use fmt;
use lexer;
use strings;

export fn main() void = {
	const input = "; Compute square of given x\n";
	const input = strings::concat(input, "(define (square x) (* x x))\n");
	const input = strings::concat(input, "; Thats it!");

	const input = strings::toutf8(input);
	let lms: lexer::lexemes = lexer::lexicalize(input);

	for (let i = 0z; i < len(lms.items); i += 1) {
		fmt::println(lms.items[i].string)!;
	};
};
