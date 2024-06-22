use io;
use strings;
use fmt;

def LPRN: u8 = 0x28; // "("
def RPRN: u8 = 0x29; // ")"

def WHSP: u8 = 0x20; //  " "
def TABL: u8 = 0x09; // "\t"
def NWLN: u8 = 0x0A; // "\n"

def QUOT: u8 = 0x22; // "\""

def SCLN: u8 = 0x3B; // ";"

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
		const s: str = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + 1]);
		let t: token = token {
			string = s,
			row = l.row,
			col = l.col,
		};
		l.col += 1;
		l.pos += 1;

		return t;
	case =>
		const s: str = strings::fromutf8_unsafe(l.data[l.pos .. l.pos + 1]);
		let t: token = token {
			string = s,
			row = l.row,
			col = l.col,
		};
		l.col += 1;
		l.pos += 1;

		return t;
	};
};

fn get_comment_token(l: *lexer) token = {

};
