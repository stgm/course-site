# Calculating final grades

To have the system calculate final grades, you can add a `calculation` section to `grading.yml`:

    calculation:
        final_grade:
            points: 25
            exam_1: 75
        final_resit:
            points: 25
            exam_2: 75

Each of those **calculations** may be run for a single student or for all students belonging to a certain schedule. Running "calculate final grades" works out every calculation that is defined, so a course with several of them may see useless non-grades calculated for the ones a given student is not up for.

The calculations are based on one or more weighed **components**, like the `points` and `exam` components in the example above. Weights are proportional to each other and do not have to add up to anything in particular. The final grade as well as component grades are on a 1--10 scheme (0 is used as an "invalid" or "failing" grade). A final grade can also be pass/fail instead, which is described under "Pass/fail" below.

The grades for components are based on the **grades** that have been assigned for individual submissions. There are several strategies to calculate a component grade, as described below.


## Grades

The `grades` section says how the grade for one submit is put together. The names match the submits defined in `submit.yml` elsewhere, and a grade may also be defined without a submit of its own. The whole section can be left out when grading is not used, or when every submit simply gets a grade typed in.

    grades:
        tentamen:
            type: points
            exam: true
            subgrades:
                python: integer
                advanced_python: integer
            calculation: python + advanced_python

- `type` is `integer`, `float`, `pass`, `points` or `percentage`, which decides how the grade is presented and entered. `float` and `points` keep their decimals; the others are rounded.

- `subgrades` are the parts a grade is made of, each of them `integer`, `float`, `pass` or `boolean`. A component can weigh a single part by naming it `grade.part`, as described under "Parts of a test".

- `calculation` is a formula over the subgrades, by name. It is not Ruby: it is a small expression language of numbers, `+ - * /`, parentheses, the comparisons `< <= > >= == !=`, `&&` and `||`, and `.floor`, `.ceil` and `.round` (optionally `.round(1)`). It also has two aggregates over the declared subgrades, `sum_all` and `count_all`, which are described under "Parts of a test" and below. The result is a number rounded to one decimal, or nothing at all if the formula fails — a subgrade that has not been filled in makes any formula that names it fail, which is how a grade stays empty until it has been graded.

- `count_all` counts the subgrades that were passed, which is `-1` throughout the system. `sum_all` adds every declared subgrade and gives nothing until all of them have a value.

- `automatic` fills subgrades from an automatic check instead of from a grader. It is a formula per subgrade over `correctness_score`, the fraction of checks that passed, between 0 and 1: `automatic: { done: -(correctness_score.floor) }` sets `done` to a pass only when everything passed. Use `calculation` to carry the subgrade into the grade itself.

- `auto_publish: true` makes the automatic check create the grade, calculate it and publish it as soon as the results come in.

- `exam: true` or `is_test: true` puts the grade in the Tests grid, where a whole group is graded in one table rather than one submission at a time. The two do the same thing. On a *component* `exam: true` means something else entirely, described under "Sitting nothing".

- `hide_calculated: true` hides the calculated grade and shows only the subgrades, to de-emphasize grades for students. `hide_subgrades: true` does the reverse.

A grade that has both `subgrades` and a `calculation` is entered through its subgrades: graders see only those fields, and the grade follows from the formula. Administrators can still type a grade directly, and a grade entered that way wins over the calculated one.


## Components

A component gathers the grades that make up one part of the course, with a weight for each, and is named in the `calculation` section to make up a final grade. Everything below is optional, and a course that does not calculate final grades needs no components at all.

    week_1:
        show_progress: true
        deadline: 7/9/25 17:00
        submits:
            weken: 1
            water: 1

- `submits` are the grades the component is made of, with their weights. What a weight means depends on the strategy: a share of the average, a number of points, or nothing at all for the strategies that pick one attempt.

- `show_progress: true` lists the results in a table on students' own progress pages. `show_overview: true` does the same on the teachers' overview, and `small_block_overview: true` renders that as compact blocks rather than a table.

- `deadline: 7/9/25 17:00` applies to every submit of the component, and `deadline_hard: true` makes it refuse submissions afterwards.

- `required: true` and `minimum: 5.5` constrain the component itself; they are described under "Average grade".

A component does not have to be used in any final grade. One that only carries `show_progress` or a `deadline` is a perfectly good way to group assignments for display.


## Average grade

When assignment grades are on a 1--10 scheme, it is a common strategy to take a weighed average. To do this, it suffices to create a section in `grading.yml` for that component and specifying the submits that are to be used for calculating the grade, with their accompanying weights.

    opdrachten_week_3:
        type: average   # <<---- (implicit)
        submits:
            basics_arrays: 1
            strings: 1
            scrabble: 2
            rna: 3
            cypher: 3
        bonus:
            goldbach: 0.25
        minimum: 5.5

Notes:

- Any *missing* grades except bonus assignments will prevent a grade to be calculated, because the average is considered to be invalid otherwise. You may add `1` grades for students who did not submit an assignment that is not required.

- Bonus assignments can be added to the total. Just specify how many points on the 1--10 scale should be added if the assignment is correct.

- Note that calculated component grades will be capped at a 10 maximum, even with bonus points added.

- A minimum can be applied, which means that the component "fails" if the threshold for the calculated grade is not met. In that case a 0 final grade for the course is automatically assigned.

- Not having 0 for any grade can also be required by setting `required: true`. A zero grade will then fail the calculation and assign a 0 final grade. This is related to `minimum:` but more useful when using pass/fail-scenarios.

- Instead of cancelling the calculation, a missing grade can be filled in with a default by setting `fill_missing: <value>`, e.g. `fill_missing: 1`.

- The lowest-scoring assignment can be dropped from the average (weight and all) by setting `drop: lowest`. Nothing is dropped if there is only one assignment.

- As with the other strategies, `attempt_required: true` means the component is not decided at all — instead of counting a missing grade as data — until every listed assignment has a grade. See the `sp1_checks` example under "Pass/fail" below.


## Maximum grade

Instead of averaging grades it is also possible to take the maximum of a series.

    punten:
        type: maximum
        submits:
            m2: 6
            m4: 6
            m6: 6
        bonus:
            goldbach: 0.25
            decryptor: 0.25
            design_challenge: 0.25
            find: 0.25
            resize: 0.25
        minimum: 5.5

Notes:

- The maximum grade is selected from any of the specified submits, and weights are *not* taken into account.

- Bonus assignments can be added to the total. Just specify how many points on the 1--10 scale should be added if the assignment is correct.

- Note that calculated component grades will be capped at a 10 maximum, even with bonus points added.

- A minimum can be applied, which means that the component "fails" if the threshold for the calculated grade is not met. In that case a 0 final grade for the course is automatically assigned.

- Unlike average grade, a missing grade for any of the submits always cancels this calculation; there is no `fill_missing` option here.


## Points

When assignments are graded pass/fail or assigned a number of points, you can use a `points` type component to calculate grades. In the example below, there are 6 points to be earned in this component. The grade is then calculated by counting the fraction of assigned points and rescaling to a 1--10 grade.

    module_2:
        type: points
        minimum: 5.5
        submits:
            queue: 1
            cards: 1
            hangman: 4

Notes:

- If explicit points are assigned in the student grade (e.g. 2 points), that will be used for the calculation.

- If "pass" (-1) is assigned in the grade, the maximum number of points is counted, as specified in the component (e.g. 4 for hangman in the example).

- Any missing grades will be counted as 0 points and thus will *not* prevent a grade to be calculated. Setting `attempt_required: true` changes this: the component is then not decided at all until every submit has a grade, just like `attempt_required` for average grade.

- A minimum can be applied, which means that the component "fails" if the threshold for the calculated grade is not met. In that case a 0 final grade is assigned.

- A maximum number of points that count towards the component can be set with `maximum: <points>`. Points earned beyond that are not counted, and the total available for the 1--10 conversion is capped at the same number, even if the submits above add up to more.

- Giving a submit a weight of `0` makes it required in a different sense: it earns no points itself, but a missing grade or a grade of 0 for it forces the whole component grade to 1, however many points were earned elsewhere.


## Parts of a test

A test that is graded in parts — a paper with a Karel section and a Python section, say — has those parts as its subgrades, and a component can name one of them directly by writing `test.part`:

    python:
        type: points
        submits:
            tentamen.python: 6

This works in every strategy, wherever a submit name is accepted. It matters when the parts of one paper belong to different components: the same sitting can hold a resit of one subject and a first attempt at another, and each part then counts towards its own component.

Notes:

- A part that was left empty is not a result at all, which is not the same as a 0. An empty subgrade means the student did not sit that part; a 0 means they sat it and scored nothing. Graders have to leave a part blank rather than enter a 0 when a student skipped it.

- A resubmit exception (-2) applies to the whole test, so none of its parts counts as a result.

- A part has to be declared as a subgrade of that test in the `grades` section, or loading `grading.yml` reports an error. A typo would otherwise read as "not made".

- For display, the parts of one test collapse back into the test itself, with their weights added up, so a component listing three parts of the same paper shows one row for it.

- A test whose parts are sat separately usually has no `calculation` of its own: a total over parts that belong to different components, some of them left empty, says nothing. Leave it out and the components carry the grading. A test whose parts are all compulsory can still total them with `sum_all`, which gives no total until every part has a value.


## Last attempt

`points_last` picks one attempt out of a series, like `pass_first` and `pass_last` do, but scores it in points instead of pass/fail. The attempt that decides it is the last one the student made:

    karel:
        type: points_last
        submits:
            tussentoets_1.karel: 3
            tussentoets_2.karel: 3

This is the rule "the last opportunity counts": a student who sits the same subject twice is held to the second result, higher or lower. Use `maximum` instead if the best attempt should count.

Notes:

- Attempts are counted in the order they are listed, not by date, exactly as under "Attempts and resits" below.

- Unlike `pass_last`, which registers a resit and therefore needs a second attempt, one attempt is enough here: a student who sat only the first opportunity is decided by it.

- The weight of the deciding attempt is its maximum number of points, and the component grade is that attempt's points rescaled to 1--10. Weights of the other attempts are not used.

- A student who made no attempt at all scores no points, giving a 1, just as a missing grade does under `points`. Set `attempt_required: true` to leave the component undecided instead, so that no final grade is registered.

- A `minimum` can be applied, as elsewhere.

- Which attempt the component came out of, and which earlier one it replaced, is recorded in the internal notes on the final grade, as described under "Attempts and resits".

Splitting a points component into several weighted components does not change the outcome, as long as each weight is that part's maximum number of points: `points_to_grade` scales linearly, so weighing the parts separately and pooling their points give the same number. That is what makes it possible to move one part of a test into a `points_last` component of its own without changing what anybody scores.


## Pass/fail

A component can also be pass/fail, in which case it produces a pass ("v") or a fail ("x") instead of a grade on the 1--10 scheme. There are four strategies: `pass_all` requires every assignment to be passed, `pass_any` requires any one of them, and `pass_first` and `pass_last` pick one attempt out of a series (see "Attempts and resits" below). None of them weighs anything, so the assignments are written as a list.

    sp1_checks:
        type: pass_all
        submits:
            - m1-passed
            - m2-passed
            - m3-passed

    sp1_exams:
        type: pass_any
        submits:
            - sp1_exam1
            - sp1_exam2
            - sp1_exam3
            - sp1_exam4

An assignment counts as passed when it has been graded "pass" (-1), or when it has a grade of 5.5 or higher. It counts as failed when it has any other grade, except a resubmit exception (-2), which counts as not graded at all.

For `pass_all`, a failed assignment is a definitive result and the component fails. An assignment that has not been graded only means the component is not decided yet, and then no final grade is assigned:

| state                                             | component      |
| ------------------------------------------------- | -------------- |
| every assignment passed                           | pass           |
| any assignment failed                             | fail           |
| otherwise (nothing failed, something not graded)  | not decided    |

For `pass_any`, as long as nothing has been graded there is no verdict, because the remaining attempts are still to come. Once something has been graded and nothing has been passed, the component fails:

| state                                             | component      |
| ------------------------------------------------- | -------------- |
| any assignment passed                             | pass           |
| nothing graded at all                             | not decided    |
| otherwise (something graded, nothing passed)      | fail           |

These strategies normally belong inside a pass/fail final grade, which is declared with `type: pass` and lists its components:

    calculation:
        sp1_final:
            type: pass
            components:
                - sp1_checks
                - sp1_exams

Such a final grade is a pass only when every one of its components is a pass. Nothing is weighed and no rounding is applied. As with every final grade, a component that is not decided yet comes first: no grade is assigned at all then, not even a failing one. Only when every component has something to report does a failed component make the final grade a fail.

Note that "all assignments passed" can also be written with the `average` strategy, because the average of a series of passes is a pass:

    sp1_checks:
        type: average          # implicit
        attempt_required: true
        required: true
        submits:
            m1-passed: 1
            m2-passed: 1
            m3-passed: 1

This still works, but `pass_all` says the same thing directly.

A pass/fail component can also be used inside a weighted (non-`type: pass`) final grade, but only at weight `0`. It then contributes nothing to the numeric average when it passes — only a fail or an ungraded state affects the result, by forcing the whole final grade to a fail or to "not decided" respectively. This is useful for a mandatory sign-off that must be completed to pass the course but should not itself earn points:

    calculation:
        eindcijfer:
            punten: 25
            tentamen: 75
            schrijfopdrachten: 0


## Optional components

A component whose name carries a `?` in a final grade is optional there: it is left out of that grade when it yielded nothing.

    calculation:
        eindcijfer:
            werkcolleges?: 6
            tentamen: 18

The weights of the remaining components then carry the whole grade, because the average divides by the weights it actually used: the tentamen above counts for everything rather than for 18 parts out of 24.

Notes:

- "Yielded nothing" means no points at all for a `points` or `points_last` component, whether because nothing was handed in or because nothing scored, and `:not_attempted` or `:missing_data` for any other strategy. The component is calculated first and then dropped, so its own strategy decides, rather than the final grade guessing from the submits.

- Anything it did yield counts in full. A student who earned a little in an optional component is graded on it, which for a `points` component means a low grade for that component. There is no threshold and no "count it only if it helps".

- Optionality belongs to the final grade, not to the component: the same component can be optional in one final grade and required in another, and the weight line says which.

- The mark works wherever components are written, including the plain list a pass/fail final grade uses: `- werkcolleges?`. It is stripped when the config is read, so the component itself is still named `werkcolleges` everywhere else.

- A `minimum` on an optional component does not sit well with it. The minimum turns "nothing earned" into a failed result rather than an absence, and a failed result is not dropped: it fails the final grade as it would anywhere else.

- When every component of a final grade is optional and none of them yielded, no grade is registered.

## Sitting nothing

A final grade normally counts a missing grade as 0 points, so a student who never turned up would still get a grade out of whatever else they handed in. An exam is not something anybody can be graded on without sitting it, so a component holding exam material says so:

    tentamen:
        type: points
        exam: true
        submits:
            tentamen: 9

Every final grade that uses such a component is then registered only once one of its exam components has been attempted. Nothing has to be repeated in the `calculation` section, and a final grade that holds no exam component is not held back at all.

Notes:

- A component counts as attempted once any of its assignments, or any part of one, has a value. A 0 is a value; an empty one is not.

- One exam component attempted is enough. The others are graded as they always were, zeros included, so a student who sat two exams out of three still gets a grade.

- Until then no grade is registered at all, not even a failing one, exactly as when a component has nothing to report.

- This is not the same as `attempt_required: true` on a component, which asks for an attempt at *that* component and leaves it undecided otherwise. Marking all the exam components that way would leave a student who sat two subjects out of three with no grade at all.

## Attempts and resits

An exam usually has several sittings, and the registration system takes two results per course: a first one and a resit. Which sitting fills which registration differs per student, because it depends on which sittings they turned up for. The `pass_first` and `pass_last` strategies express that: both take the same list of attempts, and each picks a different one out of it.

    sp1_exams:                  # the first registration
        type: pass_first
        show_progress: true
        submits:
            - sp1_exam1
            - sp1_exam2
            - sp1_exam3
            - sp1_exam4

    sp1_exams_resit:            # the resit registration
        type: pass_last
        submits:
            - sp1_exam1
            - sp1_exam2
            - sp1_exam3
            - sp1_exam4

    calculation:
        sp1_final:
            type: pass
            components:
                - sp1_checks
                - sp1_exams
        sp1_resit:
            type: pass
            components:
                - sp1_checks
                - sp1_exams_resit

An assignment counts as an **attempt made** once it has a grade with a value, whether that is a pass or a fail. An assignment that has not been graded yet is not an attempt, and neither is a resubmit exception (-2). Attempts are counted in the order they are listed, not by date, so which attempt counts as the first does not change when a grader enters an earlier one late.

- `pass_first` is decided by the first attempt made.
- `pass_last` is decided by the most recent attempt made *after* the first one. With two attempts that is the second; with three it is the third, and the second is overwritten.

Neither is decided at all when the attempt it needs was not made, and then no grade is registered — a student who never sat the exam gets no result, and a student who sat it once gets a first result and no resit. That is why the second component above needs no `show_progress`: it covers the same assignments as the first one, which already shows them.

| student                                          | sp1_final | sp1_resit |
| ------------------------------------------------ | --------- | --------- |
| checks passed, first attempt passed              | pass      | –         |
| checks passed, attempt 1 failed                  | fail      | –         |
| checks passed, attempt 1 failed, 2 passed        | fail      | pass      |
| checks passed, attempts 1 and 2 failed           | fail      | fail      |
| checks passed, attempts 1, 2 failed, 3 passed    | fail      | pass      |
| a check failed, an attempt made                  | fail      | –         |
| a check failed, no attempt made                  | –         | –         |
| checks not finished, attempt passed              | –         | –         |
| nothing made                                     | –         | –         |

When `pass_last` or `points_last` skips over an earlier attempt, that is recorded in the internal notes on the final grade, with the date each result was graded:

    6 March 2026: sp1_resit is now based on sp1_exam3 (sufficient, graded 6 March 2026).

    The previous result from sp1_exam2 (insufficient, graded 15 December 2025) was overwritten.

A grade that has been published or exported is never overwritten by a recalculation. When the calculation no longer agrees with such a grade, the grade is left exactly as it is and a note says what a recalculation would give, so that a teacher can decide whether the registration has to be corrected.
