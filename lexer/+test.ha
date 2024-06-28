use fmt;
use strings;

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
