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

def A_CH: u8 = 0x61;
def B_CH: u8 = 0x62;
def E_CH: u8 = 0x65;
def F_CH: u8 = 0x66;
def N_CH: u8 = 0x6E;
def R_CH: u8 = 0x72;
def T_CH: u8 = 0x74;
def V_CH: u8 = 0x76;

export type string_type = enum {
	REFERENCE,
	ALLOCATION,
};

export type lexeme = struct {
	string: str,
	st: string_type,
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

	const out = lms.items[lms.pos];

	return out;
};

export fn next_lexeme(lms: *lexemes) (lexeme | io::EOF) = {
	if (lms.pos >= len(lms.items)) {
		return io::EOF;
	};

	const out = lms.items[lms.pos];
	lms.pos += 1;

	return out;
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

export fn free_lexeme_content(lms: *lexeme...) void = {
	for (let i = 0z; i < len(lms); i += 1) {
		if (lms[i].st == string_type::ALLOCATION) {
			free(lms[i].string);
		};
	};
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
	const lm: lexeme = get_ref_lexeme(l, 1);
	l.col += 1;
	l.pos += 1;

	return lm;
};

fn lexicalize_comment(l: *lexer_state) lexeme = {
	let length: uint = 1;

	for (true) {
		if (l.pos + length >= len(l.data)) {
			const lm: lexeme = get_ref_lexeme(l, length);
			l.pos += length + 1;

			return lm;
		};
		switch (l.data[l.pos + length]) {
		case NWLN =>
			const lm: lexeme = get_ref_lexeme(l, length);
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

	if (l.data[l.pos] == QUOT) {
		return lexicalize_string(l);
	};

	for (true) {
		if (l.pos + length >= len(l.data)) {
			const lm: lexeme = get_ref_lexeme(l, length);
			l.pos += length;

			return lm;
		};

		switch (l.data[l.pos + length]) {
		case WHSP, TABL, LPRN, RPRN =>
			const lm: lexeme = get_ref_lexeme(l, length);

			l.pos += length;
			l.col += length;

			return lm;
		case NWLN =>
			const lm: lexeme = get_ref_lexeme(l, length);
			l.pos += length;
			l.col = 1;
			l.row += 1;

			return lm;
		case =>
			length += 1;
		};
	};
};

fn lexicalize_string(l: *lexer_state) lexeme = {
	let off: uint = 1;

	let row_offset: uint = 0;
	let col_offset: uint = 1;

	let s: []u8 = alloc([], DEF_STR_CAP);
	append(s, QUOT);

	for (true) {
		if (l.pos + off >= len(l.data)) {
			break;
		};

		switch (l.data[l.pos + off]) {
		case QUOT =>
			col_offset += 1;
			append(s, QUOT);
			break;
		case NWLN =>
			off += 1;
			row_offset += 1;
			col_offset = 0;
			l.col = 0;
		case BCSL =>
			const ch: u8 = match (get_escaped_char(l, &off)) {
				case let cch: u8 =>
					yield cch;
				case not_escape =>
					off += 1;
					l.col += 1;
					yield BCSL;
			};
			append(s, ch);
		case =>
			off += 1;
			col_offset += 1;
			append(s, l.data[l.pos + off]);
		};
	};


	const lm = lexeme {
		string = strings::fromutf8_unsafe(s),
		st = string_type::ALLOCATION,
		row = l.row,
		col = l.col,
	};
	l.row += row_offset;
	l.col += col_offset;

	return lm;
};

type not_escape = !void;

fn get_escaped_char(l: *lexer_state, off: *uint) (u8 | not_escape) = {
	let out: (u8 | not_escape) = not_escape;

	if (l.pos + *off + 1 >= len(l.data)) {
		return out;
	};

	switch (l.data[l.pos + *off + 1]) {
	case A_CH => out = 0x07;
	case B_CH => out = 0x08;
	case E_CH => out = 0x1B;
	case F_CH => out = 0x0C;
	case N_CH => out = NWLN;
	case R_CH => out = 0x0D;
	case T_CH => out = 0x09;
	case V_CH => out = 0x0B;
	case BCSL => out = BCSL;
	case QUOT => out = QUOT;
	case => return out;
	};

	*off += 2;
	l.col += 2;

	return out;
};

fn get_ref_lexeme(l: *lexer_state, length: uint) lexeme = {
	return lexeme {
		string = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + length]),
		st = string_type::REFERENCE,
		row = l.row,
		col = l.col,
	};
};

