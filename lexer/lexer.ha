use io;
use strings;

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

	// if (l.data[l.pos] == QUOT) {
	// 	return lexicalize_string(l);
	// };

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

// fn lexicalize_string(l: *lexer_state) lexeme = {
// 	let length: uint = 1;
// };

fn get_lexeme(l: *lexer_state, length: uint) lexeme = {
	return lexeme {
		string = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + length]),
		row = l.row,
		col = l.col,
	};
};

