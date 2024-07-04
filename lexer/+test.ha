use fmt;
use io;
use os;
use strings;

def INPUT_FILENAME: str = "lexer/test_suite/input.txt";
def EXPECTED_FILENAME: str = "lexer/test_suite/expected.txt";

@test fn lexeme_text_test() void = {
	const input: []str = form_input_bundle(INPUT_FILENAME);
	const expected: [][]str = form_expected_bundle(EXPECTED_FILENAME);

	assert(len(input) == len(expected));

	for (let i = 0z; i < len(input); i += 1) {
		const lms = lexicalize(strings::toutf8(input[i]));

		fmt::printfln("len(input) = {}, len(expected) = {}", len(lms.items), len(expected[i]))!;

		for (let i = 0z; i < len(lms.items); i += 1) {
			fmt::printfln("{}: {}", i, lms.items[i].string)!;
		};
		assert(len(lms.items) == len(expected[i]));

		for (let j = 0z; j < len(expected[i]); j += 1) {
			assert(lms.items[j].string == expected[i][j]);
			fmt::printfln("I: \"{}\", E: \"{}\"", lms.items[j].string, expected[i][j])!;
		};
	};
};

@test fn lexeme_position_test() void = {
	const input: []str = form_input_bundle(INPUT_FILENAME);
	const expected: [][](uint, uint) = [
		[(1, 1)],
		[(1, 4)],
		[(1, 1)],
		[(1, 5)],
		[
			(1, 1), (1, 3), (1, 5), (1, 8), (1, 10),
			(1, 12), (1, 16), (1, 18), (1, 23),
		],
		[
			(1, 1), (1, 2), (1, 9), (1, 10), (1, 17),
			(1, 18), (1, 20), (1, 21), (1, 23), (1, 25),
			(1, 26), (1, 27),
		],
		[
			(1, 1), (2, 1), (2, 2), (2, 9),
			(2, 12), (2, 19),
		],
		[
			(1, 1), (1, 2), (1, 9), (1, 16),
			(2, 1), (2, 2), (2, 9), (2, 10),
			(2, 25), (2, 26), (3, 2), (3, 3),
			(3, 6), (3, 7), (3, 8), (3, 10),
			(3, 12), (3, 13), (3, 15), (3, 17),
			(3, 18), (3, 19), (3, 20), (4, 2),
			(4, 3), (4, 4), (4, 6), (4, 8),
			(4, 9), (4, 10), (5, 2), (5, 3),
			(5, 17), (5, 18), (5, 30), (5, 31),
			(5, 38), (5, 39), (5, 41), (5, 42),
			(5, 50), (5, 51), (5, 52), (5, 53),
			(5, 54), (5, 55), (5, 56),

		],
		[
			(1, 1), (1, 2), (1, 9), (1, 12), (1, 27),
		],

	];

	for (let i = 0z; i < 7; i += 1) {
		const lms = lexicalize(strings::toutf8(input[i]));

		for (let j = 0z; j < len(expected[i]); j += 1) {
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

fn form_expected_bundle(filename: str) [][]str = {
	let result: [][]str = alloc([], 0);

	const input = os::open(filename)!;
	const input = io::drain(input)!;
	const input = strings::fromutf8(input)!;
	const input = strings::split(input, "---\n");

	for (let i = 0z; i < len(input); i += 1) {
		const line: []str = strings::split(input[i], "|\n");
		append(result, []);
		for (let j = 0z; j < len(line); j += 1) {
			if (line[j] != "") {
				append(result[i], line[j]);
			};
		};
	};

	return result;
};

