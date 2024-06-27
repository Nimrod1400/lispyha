use io;
use strings;
use fmt;

def DEF_STR_CAP: u8 = 16;

def LPRN: u8 = 0x28; // (
def RPRN: u8 = 0x29; // )

def WHSP: u8 = 0x20; //    (whitespace :D)
def TABL: u8 = 0x09; // \t
def NWLN: u8 = 0x0A; // \n

def QUOT: u8 = 0x22; // "

def BCSL: u8 = 0x5C; // \

def SCLN: u8 = 0x3B; // ;

export type token = struct {
	string: str,
	row: uint,
	col: uint,
};

export type unmatched = !token;

export type tokens = struct {
	items: []token,
	pos: uint,
};

export fn peek_token(ts: *tokens) (token | io::EOF) = {
	if (ts.pos >= len(ts.items)) {
		return io::EOF;
	};

	return ts.items[ts.pos];
};

export fn next_token(ts: *tokens) (token | io::EOF) = {
	if (ts.pos >= len(ts.items)) {
		return io::EOF;
	};
	const res = ts.items[ts.pos];
	ts.pos += 1;

	return res;
};

type lexer = struct {
	data: []u8,
	pos: uint,
	row: uint,
	col: uint,
};

export fn tokenize(input: []u8) (tokens | unmatched) = {
	let l = lexer {
		data = input,
		pos = 0,
		row = 1,
		col = 1,
	};

	let tokens = tokens {
		items = alloc([], 0),
		pos = 0,
	};

	for (true) {
		let t: token = match (get_next_token(&l)) {
			case let ct: token => yield ct;
			case void => continue;
			case io::EOF => break;
			case let cu: unmatched => return cu;
		};

		append(tokens.items, t);
	};

	return tokens;
};

fn get_next_token(l: *lexer) (token | unmatched | void | io::EOF) = {
	if (l.pos >= len(l.data)) {
		return io::EOF;
	};

	switch (l.data[l.pos]) {
	case WHSP, TABL =>
		l.col += 1;
		l.pos += 1;

		return void;
	case NWLN =>
		l.row += 1;
		l.col = 1;
		l.pos += 1;

		return void;
	case LPRN, RPRN =>
		const t: token = token {
			string = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + 1]),
			row = l.row,
			col = l.col,
		};
		l.col += 1;
		l.pos += 1;

		return t;
	case SCLN =>
		return get_comment_token(l);
	case QUOT =>
		match (get_string_token(l)) {
			case let ct: token => return ct;
			case let cu: unmatched => return cu;
		};
	case =>
		return get_word_token(l);
	};
};

fn get_comment_token(l: *lexer) token = {
	let ofst: uint = 1;

	for (true) {
		if (l.pos + ofst >= len(l.data)) {
			const t: token = token {
				string = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + ofst]),
				row = l.row,
				col = l.col,
			};
			l.pos += ofst + 1;

			return t;
		};
		switch (l.data[l.pos + ofst]) {
		case NWLN =>
			const t: token = token {
				string = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + ofst]),
				row = l.row,
				col = l.col,
			};
			l.row += 1;
			l.col = 1;
			l.pos += ofst + 1;

			return t;
		case =>
			ofst += 1;
		};
	};
};

fn get_string_token(l: *lexer) (token | unmatched) = {
	let ofst: uint = 1;
	let row_offset: uint = 0;
	let col_offset: uint = 0;

	let buf: []u8 = alloc([], DEF_STR_CAP);
	append(buf, QUOT);

	for (true) {
		if (l.pos + ofst >= len(l.data)) {
			const u: unmatched = unmatched {
				string = "UNMATCHED QUOTATION MARK",
				row = l.row,
				col = l.col,
			};
			l.pos += ofst;

			return u;
		};

		switch (l.data[l.pos + ofst]) {
		case NWLN =>
			ofst += 1;
			row_offset += 1;
			col_offset = 0;
		case BCSL =>
			append(buf, get_escaped_char(l, ofst)); // TODO
			ofst += 1;
			col_offset += 1;
		case QUOT =>
			ofst += 1;
			col_offset += 1;
			break;
		case =>
			append(buf, l.data[l.pos + ofst]);
			ofst += 1;
			col_offset += 1;
		};
	};
	append(buf, QUOT);

	const t = token {
		string = strings::fromutf8_unsafe(buf),
		row = l.row,
		col = l.col,
	};

	l.pos += ofst;
	l.row += row_offset;
	l.col += col_offset;

	return t;
};

// TODO
fn get_escaped_char(l: *lexer, ofst: uint) u8 = {
	switch (l.data[l.pos + ofst + 1]) {
	case 0x6E => return NWLN;
	case 0x74 => return TABL;
	case BCSL => return BCSL;
	case QUOT => return QUOT;
	};
};

fn get_word_token(l: *lexer) token = {
	let ofst: uint = 1;

	for (true) {
		if (l.pos + ofst >= len(l.data)) {
			const t: token = token {
				string = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + ofst]),
				row = l.row,
				col = l.col,
			};
			l.pos += ofst;

			return t;
		};

		switch (l.data[l.pos + ofst]) {
		case WHSP, TABL, LPRN, RPRN =>
			const t: token = token {
				string = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + ofst]),
				row = l.row,
				col = l.col,
			};

			l.pos += ofst;
			l.col += ofst;

			return t;
		case NWLN =>
			const t: token = token {
				string = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + ofst]),
				row = l.row,
				col = l.col,
			};
			l.pos += ofst;
			l.col = 1;
			l.row += 1;

			return t;
		case =>
			ofst += 1;
		};
	};
};

@test fn token_text_test() void = {
	const input: [_]str = [
	"(define (square x) (* x x))",                                          // 1
	strings::concat(
		";;; What is this?\n",
		"(define (hello-world) (list (quote hello) (quote world)))\n"), // 2
	strings::concat(
		"(define PI 3.14159)\n",
		";; Not sure if line above is correct.."),                      // 3
	strings::concat(
		"(import srfi-18)\n\n",
		"(define (make-n-threads n)\n",
		"(do ((i 0 (+ i 1)))\n"
		"((= i n))\n"
		"(thread-start! (make-thread (lambda () (display n))))))"),     // 4
	];
	const expected: [][]str = [
	["(", "define", "(", "square", "x", ")", "(", "*", "x", "x", ")", ")"],                 // 1
	[";;; What is this?",
		"(", "define", "(", "hello-world", ")",
		"(", "list", "(", "quote", "hello", ")", "(", "quote", "world", ")", ")", ")"], // 2
	["(", "define", "PI", "3.14159", ")", ";; Not sure if line above is correct.."],        // 3
	["(", "import", "srfi-18", ")",
		"(", "define", "(", "make-n-threads", "n", ")",
		"(", "do", "(", "(", "i", "0", "(", "+", "i", "1", ")", ")", ")",
		"(", "(", "=", "i", "n", ")", ")",
		"(", "thread-start!", "(", "make-thread", "(", "lambda", "(", ")",
		"(", "display", "n", ")", ")", ")", ")", ")", ")"],                            // 4
	];

	assert(len(input) == len(expected));

	for (let i = 0z; i < len(input); i += 1) {
		const tokens = tokenize(strings::toutf8(input[i])) as tokens;
		fmt::printfln("Test input {}\n: Tokens got: {}, and expected: {}", i, len(tokens.items), len(expected[i]))!;
		assert(len(tokens.items) == len(expected[i]));

		for (let j = 0z; j < len(expected[i]); j += 1) {
			fmt::printfln("Token got: `{}`, and expected: `{}`", tokens.items[j].string, expected[i][j])!;
			assert(tokens.items[j].string == expected[i][j]);
		};
	};
};

// @test fn token_loc_test() void = {

// };
