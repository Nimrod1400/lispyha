use bufio;
use fmt;
use io;
use os;
use strings;

@test fn lexeme_text_test() void = {
	const input: []str = form_input_bundle("lexer/test_suite/input.txt");
	const expected: [][]str = form_expected_bundle("lexer/test_suite/expected.txt");

	fmt::printfln("Input len: {}\nExpected len: {}", len(input), len(expected))!;

	assert(len(input) == len(expected));

	for (let i = 0z; i < len(input); i += 1) {
		const lms = lexicalize(strings::toutf8(input[i]));
		fmt::printfln("Test input {}\n: Lexemes got: {}, and expected: {}", i + 1, len(lms.items), len(expected[i]))!;
		assert(len(lms.items) == len(expected[i]));

		for (let j = 0z; j < len(expected[i]); j += 1) {
			fmt::printfln("Lexeme got: `{}`, and expected: `{}`", lms.items[j].string, expected[i][j])!;
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

	fmt::println("Expecteds:\n")!;
	print_result(result);

	return result;

};

fn print_result(input: [][]str) void =  {
	for (let i = 0z; i < len(input); i += 1) {
		for (let j = 0z; j < len(input[i]); j += 1) {
			fmt::printf("[{}], ", input[i][j])!;
		};
		fmt::println("\nNEXT:")!;
	};
};
