// Replacement for GhostText's advanced-editors-messenger.js: the bridge that
// runs in the page itself (world: MAIN) and talks to code editors the content
// script can't reach - CodeMirror 5/6, Monaco and Ace.
//
// Protocol with ghost-text.js (unchanged, so the content script needs no
// changes for it): `gt:get` on the editor element starts a bridge, the bridge
// answers with `gt:input` {value, syntax} whenever the text changes, the
// content script puts new text in the `gt-value` attribute and fires
// `gt:transfer`, and `gt:kill` tears the bridge down.
//
// Fixes over upstream 26.5.12:
//  * its throttle sent the arguments of the FIRST call in each 50 ms window,
//    so Ace (which reports a multi-line comment toggle as one change per
//    line) sent the text with only the first line changed;
//  * text from the editor replaced the whole document (Monaco's setValue
//    also wiped the page's undo history and reset the cursor) - now only the
//    changed span is replaced;
//  * Ace ignored changes the page made itself (only edits made through an
//    Ace command were sent), and could ignore incoming text mid-command;
//  * only CodeMirror 6 handled gt:kill, so reconnecting a field doubled up
//    its listeners;
//  * CodeMirror 6 wasn't detected at all on current versions (@codemirror/view
//    renamed the DOM property it looked for), and was polled every 500 ms -
//    now every 100 ms, cheaply, since its documents are immutable;
//  * the editor's language is sent along (Monaco language id, Ace mode,
//    CodeMirror mode), so Neovim can pick the filetype.

(() => {
	// injected once per activation; one listener per page is enough
	if (globalThis.ghostTextMessengerReady) return;
	globalThis.ghostTextMessengerReady = true;

	const bridges = new WeakMap();

	/** Run `fn` at most once per `ms`, always against the latest state. */
	function throttle(ms, fn) {
		let timer;
		return () => {
			timer ??= setTimeout(() => {
				timer = undefined;
				fn();
			}, ms);
		};
	}

	/** Smallest single replacement turning `a` into `b` (never splits a surrogate pair). */
	function diff(a, b) {
		const max = Math.min(a.length, b.length);
		let start = 0;
		while (start < max && a.charCodeAt(start) === b.charCodeAt(start)) start++;
		if (start > 0 && isHighSurrogate(a.charCodeAt(start - 1))) start--;
		let end = 0;
		while (end < max - start && a.charCodeAt(a.length - 1 - end) === b.charCodeAt(b.length - 1 - end)) end++;
		if (end > 0 && isLowSurrogate(a.charCodeAt(a.length - end))) end--;
		return {from: start, to: a.length - end, insert: b.slice(start, b.length - end)};
	}

	const isHighSurrogate = c => c >= 0xd800 && c <= 0xdbff;
	const isLowSurrogate = c => c >= 0xdc00 && c <= 0xdfff;

	function emit(element, value, syntax) {
		element.dispatchEvent(new CustomEvent('gt:input', {detail: {value, syntax: syntax || ''}}));
	}

	/** Common wiring: send now, send (throttled) on change, apply transfers, clean up on kill. */
	function bridge(element, editor) {
		let applying = false;
		const send = () => emit(element, editor.get(), editor.syntax());
		const changed = throttle(50, send);
		const onChange = () => {
			if (!applying) changed();
		};

		const stop = editor.listen(onChange, changed);
		const onTransfer = () => {
			const next = element.getAttribute('gt-value') ?? '';
			const current = editor.get();
			if (next === current) return;
			applying = true;
			try {
				editor.replace(diff(current, next), next);
			} catch (error) {
				console.warn('GhostText: falling back to replacing the whole text', error);
				editor.replace({from: 0, to: current.length, insert: next}, next);
			} finally {
				applying = false;
			}
		};

		element.addEventListener('gt:transfer', onTransfer);
		const kill = () => {
			stop();
			element.removeEventListener('gt:transfer', onTransfer);
			element.removeEventListener('gt:kill', kill);
			bridges.delete(element);
		};

		element.addEventListener('gt:kill', kill);
		bridges.set(element, kill);
		send();
	}

	/** EditorView behind a .cm-content, as EditorView.findFromDOM does it. */
	function codeMirror6View(element) {
		// @codemirror/view renamed the DOM back-reference cmView -> cmTile (6.39)
		const tile = element.cmTile ?? element.cmView;
		return tile?.root?.view ?? tile?.rootView?.view ?? tile?.view;
	}

	function codeMirror6(view) {
		return {
			get: () => view.state.doc.toString(),
			syntax: () => view.contentDOM.dataset.language,
			listen(onChange) {
				let doc = view.state.doc;
				// CM6 offers no change event without access to its modules, so poll -
				// documents are immutable, so an unchanged one is the same object
				const timer = setInterval(() => {
					if (view.state.doc !== doc) {
						doc = view.state.doc;
						onChange();
					}
				}, 100);
				return () => clearInterval(timer);
			},
			replace({from, to, insert}) {
				view.dispatch({changes: {from, to, insert}, userEvent: 'input.ghosttext'});
			},
		};
	}

	function codeMirror5(element) {
		const cm = element.CodeMirror;
		return {
			get: () => cm.getValue(),
			syntax() {
				const mode = cm.getOption('mode');
				return typeof mode === 'string' ? mode : mode?.name;
			},
			listen(onChange, onMeta) {
				cm.on('changes', onChange);
				cm.on('optionChange', onMeta);
				return () => {
					cm.off('changes', onChange);
					cm.off('optionChange', onMeta);
				};
			},
			replace({from, to, insert}) {
				cm.replaceRange(insert, cm.posFromIndex(from), cm.posFromIndex(to), '+ghosttext');
			},
		};
	}

	function monaco(element) {
		const model = globalThis.monaco.editor.getModel(element.dataset.uri);
		return {
			get: () => model.getValue(),
			syntax: () => model.getLanguageId?.() ?? model.getModeId?.(),
			listen(onChange, onMeta) {
				const subscriptions = [model.onDidChangeContent(onChange), model.onDidChangeLanguage(onMeta)];
				return () => {
					for (const subscription of subscriptions) subscription.dispose();
				};
			},
			replace({from, to, insert}) {
				const start = model.getPositionAt(from);
				const end = model.getPositionAt(to);
				model.pushStackElement();
				model.pushEditOperations(
					[],
					[{
						range: {
							startLineNumber: start.lineNumber,
							startColumn: start.column,
							endLineNumber: end.lineNumber,
							endColumn: end.column,
						},
						text: insert,
					}],
					() => null,
				);
				model.pushStackElement();
			},
		};
	}

	function ace(element) {
		const {editor} = element.env;
		return {
			get: () => editor.session.getValue(),
			syntax: () => editor.session.$modeId ?? editor.session.getMode?.().$id,
			listen(onChange, onMeta) {
				// editor-level events keep working when the page swaps sessions
				editor.on('change', onChange);
				editor.on('changeSession', onMeta);
				editor.on('changeMode', onMeta);
				return () => {
					editor.off('change', onChange);
					editor.off('changeSession', onMeta);
					editor.off('changeMode', onMeta);
				};
			},
			replace({from, to, insert}) {
				const {doc} = editor.session;
				editor.session.replace({start: doc.indexToPosition(from), end: doc.indexToPosition(to)}, insert);
			},
		};
	}

	document.body.addEventListener('gt:get', ({target: element}) => {
		bridges.get(element)?.();
		let editor;
		const cmView = codeMirror6View(element);
		if (cmView) {
			editor = codeMirror6(cmView);
		} else if (element.CodeMirror) {
			editor = codeMirror5(element);
		} else if (element.classList.contains('monaco-editor')) {
			editor = monaco(element);
		} else if (element.env?.editor) {
			editor = ace(element);
		} else {
			return;
		}

		bridge(element, editor);
	});

	console.log('Advanced editors messenger ready');
})();
