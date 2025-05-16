# CMSC-132-Postfix-Calculator
A MIPS implementation of a postfix evaluator with input validation.

# How the postfix calculator works:
- The calculator accepts properly formatted postfix expressions.<br>
Format of the input should be:<br>
- Operands and operators are separated strictly by a single space.
Separation of tokens (operands and operators) using two or more spaces will lead to an error.
Conversely, not separating an operand to an operator will lead to an error.<br>
- Improper postfix notation are not accepted and will return an error <br>
- The calculator loops through accepting user inputs. The program will only end if the user type the word
"exit".<br>
- Typing the word "exit" in any other format than the format shown will return an error.
