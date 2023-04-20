require "test_helper"

class User::FinalGradeCalculatorTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
   test "grade" do
       Settings.grading = {"templates"=>
 {1=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  4=>
   {"type"=>"float",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done==-1 && 1.5 || 0",
    "hide_calculated"=>true},
  2=>{"type"=>"float", "subgrades"=>{"cijfer"=>"float"}, "calculation"=>"cijfer", "hide_calculated"=>true},
  3=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true}},
"grades"=>
 {"scratch"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "hello"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "population"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "conversion"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "mario"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "soda"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "caffeine"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "strings"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "scrabble"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "rna"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "cypher"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "functions"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "tiles"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "calendar"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "algorithms"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "measurements"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "sort"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "big_o"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "complexity_puzzle"=>
   {"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "beatles"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "whodunit"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "filter"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "speller"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "speller_questions"=>
   {"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "goldbach"=>
   {"type"=>"float",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done==-1 && 1.5 || 0",
    "hide_calculated"=>true},
  "decryptor"=>
   {"type"=>"float",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done==-1 && 1.5 || 0",
    "hide_calculated"=>true},
  "design_challenge"=>
   {"type"=>"float",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done==-1 && 1.5 || 0",
    "hide_calculated"=>true},
  "find"=>
   {"type"=>"float",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done==-1 && 1.5 || 0",
    "hide_calculated"=>true},
  "resize"=>
   {"type"=>"float",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done==-1 && 1.5 || 0",
    "hide_calculated"=>true},
  "basics_variables"=>
   {"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "basics_control_flow"=>
   {"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "basics_arrays"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "basics_functions"=>
   {"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "tentamen-oefening-regen"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "tentamen-oefening-rechthoeken"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "tentamen-oefening-hoofdletters"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "tentamen-oefening-driehoek"=>
   {"type"=>"pass",
    "subgrades"=>{"done"=>"boolean"},
    "automatic"=>{"done"=>"-(correctness_score.floor)"},
    "calculation"=>"done",
    "auto_publish"=>true,
    "hide_calculated"=>true},
  "m2"=>
   {"type"=>"float",
    "subgrades"=>{"points"=>"integer"},
    "calculation"=>"(points / 6.0 * 9 + 1).round(1)",
    "hide_calculated"=>true},
  "m3"=>
   {"type"=>"float",
    "subgrades"=>{"points"=>"integer"},
    "calculation"=>"(points / 6.0 * 9 + 1).round(1)",
    "hide_calculated"=>true},
  "m4"=>
   {"type"=>"float",
    "subgrades"=>{"points"=>"integer"},
    "calculation"=>"(points / 6.0 * 9 + 1).round(1)",
    "hide_calculated"=>true},
  "m5"=>
   {"type"=>"float",
    "subgrades"=>{"points"=>"integer"},
    "calculation"=>"(points / 6.0 * 9 + 1).round(1)",
    "hide_calculated"=>true},
  "m6"=>
   {"type"=>"float",
    "subgrades"=>{"points"=>"integer"},
    "calculation"=>"(points / 6.0 * 9 + 1).round(1)",
    "hide_calculated"=>true},
  "m7"=>
   {"type"=>"float",
    "subgrades"=>{"points"=>"integer"},
    "calculation"=>"(points / 6.0 * 9 + 1).round(1)",
    "hide_calculated"=>true},
  "oefententamen"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true},
  "tentamen"=>{"type"=>"float", "subgrades"=>{"cijfer"=>"float"}, "calculation"=>"cijfer", "hide_calculated"=>true},
  "hertentamen"=>{"type"=>"pass", "subgrades"=>{"done"=>"boolean"}, "calculation"=>"done", "hide_calculated"=>true}},
"calculation"=>
 {"eindcijfer"=>{"punten"=>25, "tentamen"=>75}, "eindcijfer_herkansing"=>{"punten"=>25,"hertentamen"=>75}},
"opdrachten_week_1"=>
 {"show_progress"=>true,
  "convert_passes_to_grade"=>true,
  "submits"=>{"scratch"=>1, "basics_variables"=>1, "hello"=>1, "basics_control_flow"=>1, "population"=>1}},
"opdrachten_week_2"=>
 {"show_progress"=>true,
  "convert_passes_to_grade"=>true,
  "submits"=>{"conversion"=>1, "mario"=>1, "soda"=>1, "caffeine"=>1}},
"opdrachten_week_3"=>
 {"show_progress"=>true,
  "convert_passes_to_grade"=>true,
  "submits"=>{"basics_arrays"=>1, "strings"=>1, "scrabble"=>1, "rna"=>1, "cypher"=>1}},
"opdrachten_week_4"=>
 {"show_progress"=>true,
  "convert_passes_to_grade"=>true,
  "submits"=>{"functions"=>1, "tiles"=>1, "basics_functions"=>1, "calendar"=>1}},
"opdrachten_week_5"=>
 {"show_progress"=>true,
  "convert_passes_to_grade"=>true,
  "submits"=>{"algorithms"=>1, "measurements"=>1, "sort"=>1, "big_o"=>1, "complexity_puzzle"=>1}},
"opdrachten_week_6"=>
 {"show_progress"=>true, "convert_passes_to_grade"=>true, "submits"=>{"beatles"=>1, "whodunit"=>1, "filter"=>1}},
"opdrachten_week_7"=>
 {"show_progress"=>true, "convert_passes_to_grade"=>true, "submits"=>{"speller_questions"=>1, "speller"=>1}},
"punten"=>
 {"type"=>"maximum",
  "show_progress"=>true,
  "submits"=>{"m2"=>6, "m4"=>6, "m6"=>6},
  "bonus"=>
   {"goldbach"=>0.16666, "decryptor"=>0.16666, "design_challenge"=>0.16666, "find"=>0.16666, "resize"=>0.16666}},
"tentamenoefeningen"=>
 {"submits"=>
   {"tentamen-oefening-regen"=>1,
    "tentamen-oefening-rechthoeken"=>1,
    "tentamen-oefening-hoofdletters"=>1,
    "tentamen-oefening-driehoek"=>1,
    "oefententamen"=>1}},
"tentamen"=>{"show_progress"=>true, "required"=>true, "submits"=>{"tentamen"=>1}},
"hertentamen"=>{"show_progress"=>true, "required"=>true, "submits"=>{"hertentamen"=>1}}}

        assert_equal 6.5, User::FinalGradeCalculator.run_for(User.first.all_submits)['eindcijfer']
   end

end
