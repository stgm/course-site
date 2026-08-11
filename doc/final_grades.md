# Calculating final grades

To have the system calculate final grades, you can add a `calculation` section to `grading.yml`:

    calculation:
        final_grade:
            points: 25
            exam_1: 75
        final_resit:
            points: 25
            exam_2: 75

Each of those **calculations** may be run for a single student or for all students belonging to a certain schedule.

The calculations are based on one or more weighed **components**, like the `points` and `exam` components in the example above. The final grade as well as component grades are on a 1--10 scheme (0 is used as an "invalid" or "failing" grade). A final grade can also be pass/fail instead, which is described under "Pass/fail" below.

The grades for components are based on the **grades** that have been assigned for individual submissions. There are several strategies to calculate a component grade, as described below.


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

- Any missing grades will be counted as 0 points and thus will *not* prevent a grade to be calculated.

- A minimum can be applied, which means that the component "fails" if the threshold for the calculated grade is not met. In that case a 0 final grade is assigned.


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

These strategies only make sense inside a pass/fail final grade, which is declared with `type: pass` and lists its components:

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

When `pass_last` skips over an earlier attempt, that is recorded in the internal notes on the final grade, with the date each result was graded:

    6 March 2026: sp1_resit is now based on sp1_exam3 (sufficient, graded 6 March 2026).

    The previous result from sp1_exam2 (insufficient, graded 15 December 2025) was overwritten.

A grade that has been published or exported is never overwritten by a recalculation. When the calculation no longer agrees with such a grade, the grade is left exactly as it is and a note says what a recalculation would give, so that a teacher can decide whether the registration has to be corrected.
