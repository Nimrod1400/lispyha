use io;
use strings;
use fmt;

def DEF_LMS_CAP: u8 = 128;
def DEF_STR_CAP: u8 = 16;

def LPRN: u8 = 0x28; // (
def RPRN: u8 = 0x29; // )

def WHSP: u8 = 0x20; //    (whitespace)
def TABL: u8 = 0x09; // \t
def NWLN: u8 = 0x0A; // \n

def QUOT: u8 = 0x22; // "

def BCSL: u8 = 0x5C; // \

def SCLN: u8 = 0x3B; // ;

export type lexeme = struct {
	string: str,
	row: uint,
	col: uint,
};

export type lexemes = struct {
	items: []lexeme,
	pos: uint,
};

export fn peek_lexeme(lms: *lexemes) (lexeme | io::EOF) = {
	if (lms.pos >= len(lms.items)) {
		return io::EOF;
	};

	const lm = lms.items[lms.pos];

	return lm;
};

export fn next_lexeme(lms: *lexemes) (lexeme | io::EOF) = {
	if (lms.pos >= len(lms.items)) {
		return io::EOF;
	};

	const lm = lms.items[lms.pos];
	lms.pos += 1;

	return lm;
};

type lexer_state = struct {
	data: []u8,
	pos: uint,
	row: uint,
	col: uint,
};

export fn lexicalize(input: []u8) lexemes = {
	let l = lexer_state {
		data = input,
		pos = 0,
		row = 1,
		col = 1,
	};

	let lms = lexemes {
		items = alloc([], DEF_LMS_CAP),
		pos = 0,
	};

	for (true) {
		if (l.pos >= len(l.data)) {
			break;
		};

		let lm: lexeme = match (lexicalize_next(&l)) {
			case let clm: lexeme => yield clm;
			case void => continue;
		};

		append(lms.items, lm);
	};

	return lms;
};

fn lexicalize_next(l: *lexer_state) (lexeme | void) = {
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
		return lexicalize_paren(l);
	case SCLN =>
		return lexicalize_comment(l);
	case =>
		return lexicalize_atom(l);
	};
};

fn lexicalize_paren(l: *lexer_state) lexeme = {
	const lm: lexeme = get_lexeme(l, 1);
	l.col += 1;
	l.pos += 1;

	return lm;
};

fn lexicalize_comment(l: *lexer_state) lexeme = {
	let length: uint = 1;

	for (true) {
		if (l.pos + length >= len(l.data)) {
			const lm: lexeme = get_lexeme(l, length);
			l.pos += length + 1;

			return lm;
		};
		switch (l.data[l.pos + length]) {
		case NWLN =>
			const lm: lexeme = get_lexeme(l, length);
			l.row += 1;
			l.col = 1;
			l.pos += length + 1;

			return lm;
		case =>
			length += 1;
		};
	};
};

fn lexicalize_atom(l: *lexer_state) lexeme = {
	let length: uint = 1;

	for (true) {
		if (l.pos + length >= len(l.data)) {
			const lm: lexeme = get_lexeme(l, length);
			l.pos += length;

			return lm;
		};

		switch (l.data[l.pos + length]) {
		case WHSP, TABL, LPRN, RPRN =>
			const lm: lexeme = get_lexeme(l, length);

			l.pos += length;
			l.col += length;

			return lm;
		case NWLN =>
			const lm: lexeme = get_lexeme(l, length);
			l.pos += length;
			l.col = 1;
			l.row += 1;

			return lm;
		case =>
			length += 1;
		};
	};
};

fn get_lexeme(l: *lexer_state, length: uint) lexeme = {
	return lexeme {
		string = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + length]),
		row = l.row,
		col = l.col,
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
		const lms = lexicalize(strings::toutf8(input[i]));
		fmt::printfln("Test input {}\n: Tokens got: {}, and expected: {}", i, len(lms.items), len(expected[i]))!;
		assert(len(lms.items) == len(expected[i]));

		for (let j = 0z; j < len(expected[i]); j += 1) {
			fmt::printfln("Token got: `{}`, and expected: `{}`", lms.items[j].string, expected[i][j])!;
			assert(lms.items[j].string == expected[i][j]);
		};
	};
};

// @test fn token_loc_test() void = {

// };
