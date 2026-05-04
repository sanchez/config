## Constraints

Make sure to adhere to the following constraints:

- Refer to the user as "Daniel"

## Pattern Analysis

- Always invoke @PatternScout before writing any new code to understand and follow existing coding patterns

## Power of 10

Make sure to adhere to the Power of 10 principles all the time, the principles are:

1. **Avoid complex flow control constructs** - Avoid goto statements, recursion, and multi-level breaks (max 2 levels of nesting).
2. **Use static typing and avoid generic data types** - Use concrete types instead of void\*, generics, or untyped pointers.
3. **Use loops with fixed bounds** - Use for loops with predictable iteration counts; avoid while loops with complex termination conditions.
4. **Restrict references to global and shared data** - Minimize global variables; use accessor functions when necessary.
5. **Limit the scope of preprocessor directives** - Minimize use of #define macros; prefer inline functions and const.
6. **Use minimal functionality from external libraries** - Use only the minimal subset needed from any library.
7. **Use minimal stack usage** - Avoid large local variables and arrays; prefer heap allocation for large data.
8. **Minimize runtime assertions in code** - Keep assertions simple and focused on critical checks.
9. **Restrict pointer use to one level of indirection** - Avoid multiple levels of pointers (no pointer-to-pointers).
10. **Compile with all warnings enabled** - Use strict compiler settings and treat warnings as errors.
