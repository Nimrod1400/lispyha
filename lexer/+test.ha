use bufio;
use fmt;
use io;
use os;
use strconv;
use strings;

def INPUT_FILENAME: str = "lexer/test_suite/input.txt";
def EXPECTED_LITERALS_FILENAME: str = "lexer/test_suite/expected_literals.txt";
def EXPECTED_POSITIONS_FILENAME: str = "lexer/test_suite/expected_positions.txt";

@test fn lexeme_literal_test() void = {
	const input: []str = form_input_bundle(INPUT_FILENAME);
	const expected: [][]str = form_expected_literals_bundle(EXPECTED_LITERALS_FILENAME);

	assert(len(input) == len(expected));

	for (let i = 0z; i < len(input); i += 1) {
		const lms = lexicalize(strings::toutf8(input[i]));

		assert(len(lms.items) == len(expected[i]));

		for (let j = 0z; j < len(expected[i]); j += 1) {
			let peeked_literal: str = (peek_lexeme(&lms) as lexeme).literal;
			let read_literal: str = (read_lexeme(&lms) as lexeme).literal;
			assert(read_literal == expected[i][j]);
			assert(peeked_literal == read_literal);
		};

		assert(read_lexeme(&lms) is io::EOF);
	};
};

@test fn lexeme_position_test() void = {
	const input: []str = form_input_bundle(INPUT_FILENAME);
	const expected: [][](uint, uint) = form_expected_position_bundle(EXPECTED_POSITIONS_FILENAME);

	for (let i = 0z; i < len(input); i += 1) {
		const lms = lexicalize(strings::toutf8(input[i]));

		for (let j = 0z; j < len(expected[i]); j += 1) {
			fmt::printfln("Got: ({}, {}), Exp: ({}, {})",
				lms.items[j].row, lms.items[j].col,
				expected[i][j].0, expected[i][j].1)!;

			assert(lms.items[j].row == expected[i][j].0);
			assert(lms.items[j].col == expected[i][j].1);
		};
	};
};

fn form_input_bundle(filename: str) []str = {
	const input = os::open(filename)!;
	const input = io::drain(input)!;
	const input = strings::fromutf8(input)!;
	const input = strings::split(input, "---\n");

	return input;
};

fn form_expected_literals_bundle(filename: str) [][]str = {
	let out: [][]str = alloc([], 0);

	const input = os::open(filename)!;
	const input = io::drain(input)!;
	const input = strings::fromutf8(input)!;
	const input = strings::split(input, "---\n");

	for (let i = 0z; i < len(input); i += 1) {
		const literal: []str = strings::split(input[i], "|\n");
		append(out, []);
		for (let j = 0z; j < len(literal); j += 1) {
			if (literal[j] != "") {
				append(out[i], literal[j]);
			};
		};
	};

	return out;
};

fn form_expected_position_bundle(filename: str) [][](uint, uint) = {
	let out: [][](uint, uint) = alloc([], 0);

	const input = os::open(filename)!;
	const input = io::drain(input)!;
	const input = strings::fromutf8(input)!;
	const input = strings::split(input, "---\n");

	for (let i = 0z; i < len(input); i += 1) {
		const positions: []str = strings::split(input[i], ", ");
		append(out, []);
		for (let j = 0z; j < len(positions); j += 1) {
			const row: str = strings::split(positions[j], " ")[0];
			const col: str = strings::split(positions[j], " ")[1];

			const row: str = strings::trim(row);
			const col: str = strings::trim(col);

			const position: (uint, uint) = (strconv::stou(row) as uint, strconv::stou(col) as uint);

			append(out[i], position);
		};
	};

	return out;
};
