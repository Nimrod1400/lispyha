use io;
use strings;
use fmt;

export type token = struct {
	data: []rune,
	row: uint,
	col: uint,
};

export type unmatched = !token;

export type tokens = struct {
	data: []token,
	current_index: uint,
};

export fn peek_token(ts: *tokens) (token | io::EOF) = {
	if (ts.current_index >= len(ts.data)) {
		return io::EOF;
	};

	return ts.data[ts.current_index];
};

export fn next_token(ts: *tokens) (token | io::EOF) = {
	if (ts.current_index >= len(ts.data)) {
		return io::EOF;
	};
	const res = ts.data[ts.current_index];
	ts.current_index += 1;

	return res;
};

type lexer = struct {
	iter: strings::iterator,
	row: uint,
	col: uint,
};

export fn tokenize(input: *str) (tokens | unmatched) = {
	let l = lexer {
		iter = strings::iter(*input),
		row = 1,
		col = 1,
	};

	let tokens = tokens {
		data = [],
		current_index = 0,
	};

	for (true) {
		let t: token = match (get_next_token(&l)) {
		case let t_: token => yield t_;
		case void => continue;
		case io::EOF => break;
		case let u_: unmatched => return u_;
		};

		append(tokens.data, t);
	};

	return tokens;
};

fn get_next_token(l: *lexer) (token | unmatched | void | io::EOF) = {
	let ch: rune = match(strings::next(&l.iter)) {
	case let r_: rune => yield r_;
	case void => return io::EOF;
	};

	switch (ch) {
	case ' ', '\t' =>
		l.col += 1;
		return void;
	case '\n' =>
		l.row += 1;
		l.col = 1;
		return void;
	case '(', ')' =>
		let t: token = token {
			data = alloc([ch...], 1),
			row = l.row,
			col = l.col,
		};
		l.col += 1;

		return t;
	case =>
		let t: token = token {
			data = alloc([ch...], 1),
			row = l.row,
			col = l.col,
		};
		l.col += 1;

		return t;
	};
};
