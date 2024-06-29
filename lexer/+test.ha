use bufio;
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
		assert(len(lms.items) == len(expected[i]));

		for (let j = 0z; j < len(expected[i]); j += 1) {
			assert(lms.items[j].string == expected[i][j]);
		};
	};
};

fn form_input_bundle(filename: str) []str = {
	const input = os::open(filename)!;
	const input = io::drain(input)!;
	const input = strings::fromutf8(input)!;
	const input = strings::split(input, "---");

	return input;
};

fn form_expected_bundle(filename: str) [][]str = {
	let result: [][]str = alloc([], 0);

	const input = os::open(filename)!;
	const input = io::drain(input)!;
	const input = strings::fromutf8(input)!;
	const input = strings::split(input, "---");

	for (let i = 0z; i < len(input); i += 1) {
		const line: []str = strings::split(input[i], "\n");
		append(result, []);
		for (let j = 0z; j < len(line); j += 1) {
			if (line[j] != "") {
				append(result[i], line[j]);
			};
		};
	};

	return result;

};

