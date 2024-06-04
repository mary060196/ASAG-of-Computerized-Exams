# Script: extract_exams_data.cmd
# Author: Miriam Briskman
# Date: 05/30/2024

#!/bin/bash

# Some ANSI colors to be used within the messages output to the console:
WHITE=$'\e[1;37m'
BLACK=$'\e[1;30m'
NC=$'\e[0m' # No Color
RED_BG=$'\e[41m'
BLU_BG=$'\e[46m'
PINK_BG=$'\e[45m'
GRN_BG=$'\e[42m'
BRWN_BG=$'\e[48;5;222m'

# Function that checks if a command name (passed as an argument) exists on the device and is added to the PATH enviromental variable:
exists()
{
  command -v "$1" >/dev/null 2>&1
}

# Variable that records if at least one error occured:
are_errors=0

# Confirm that pdftk and pdftotext are installed and accessible:
if ! exists pdftk; then
  echo "${RED_BG}${WHITE}ERROR${NC} pdftk (\"PDF Toolkit\") is not installed." >&2
  echo "${GRN_BG}${WHITE}INFO${NC} pdftk is needed to extract student answers as text from questionnaires." >&2
  echo "${BLU_BG}${WHITE}NOTE${NC} Please install pdftk (https://www.pdflabs.com/tools/pdftk-server/), add the path to the pdftk program to the PATH environmental variable, and only then re-run this script." >&2
  echo '---------------------------------------'
  are_errors=1
fi

if ! exists pdftotext; then
  echo "${RED_BG}${WHITE}ERROR${NC} pdftotext (\"PDF-to-Text\") is not installed." >&2
  echo "${GRN_BG}${WHITE}INFO${NC} pdftotext is needed to extract exam questions and solutions as text from the solution files." >&2
  echo "${BLU_BG}${WHITE}NOTE${NC} Please install pdftotext (https://www.xpdfreader.com/download.html) under the \"Download the Xpdf command line tools\", add the path to the pdftotext program to the PATH environmental variable, and only then re-run this script." >&2
  echo '---------------------------------------'
  are_errors=1
fi

if [ $are_errors -eq 1 ]; then
  echo 'Exiting script due to errors...'
  exit 1
fi

# Read in the folder where the training exam folders (questionnaires and solutions) are located:
read -p "Please enter the path to the training folder: " train_folder
echo "The training folder you entered is: ${train_folder}"
train_questionnaires_folder="${train_folder}/questionnaires/"
train_solutions_folder="${train_folder}/solutions/"
# Read in the folder where the test exam folders are located:
read -p "Please enter the path to the test folder: " test_folder
echo "The test folder you entered is: ${test_folder}"
test_questionnaires_folder="${test_folder}/questionnaires/"
test_solutions_folder="${test_folder}/solutions/"

# Create folders where the extracted text will be stored:
mkdir -p train_extracted_raw_data
mkdir -p test_extracted_raw_data
# Extract text from each of the questionnaires and solutions:
let count=0
for f in "$train_questionnaires_folder"/*
do
        filename="$(basename $f)"
	echo "Extracting training raw text student answers from questionnaire file $(basename $f) ..."
	pdftk "$f" dump_data_fields_utf8 > "train_extracted_raw_data/${filename%.*}_student_answers.txt"
	let count=count+1
done

let count=0
for f in "$train_solutions_folder"/*
do
	filename="$(basename $f)"
	echo "Extracting training raw text questions & solutions from solutions file $(basename $f) ..."
	pdftotext "$f" "train_extracted_raw_data/${filename%.*}_questions_solutions.txt"
        let count=count+1
done

let count=0
for f in "$test_questionnaires_folder"/*
do
	filename="$(basename $f)"
	echo "Extracting test raw text student answers from questionnaire file $(basename $f) ..."
        pdftk "$f" dump_data_fields_utf8 > "test_extracted_raw_data/${filename%.*}_student_answers.txt"
        let count=count+1
done

let count=0
for f in "$test_solutions_folder"/*
do
	filename="$(basename $f)"
	echo "Extracting test raw text questions & solutions from solutions file $(basename $f) ..."
        pdftotext "$f" "test_extracted_raw_data/${filename%.*}_questions_solutions.txt"
        let count=count+1
done

echo '---------------------------------------'

# Since the created text files contain irrelevant data (e.g., data from the files' headers), we need to clean the files before proceeding to extract the questions, solutions, and student answers:
let count=0
for f in "train_extracted_raw_data"/*
do
        filename="$(basename $f)"
	if [[ $filename == *_student_answers.txt ]]
	then
		echo "Cleaning train file $filename ..."
		sed --regexp-extended -e 's/([0-9]+)\./\1\)/g' -e 's/,//g' -e 's|Type your answer to question [0-9]+ here.||g' -e '/^FieldType: /d' -e 's/^FieldName: ([0-9]+)$/\1\. /g' -e '/^FieldFlags: /d' -e '/^FieldJustification: /d' -e 's|^FieldValue: ||g' -e 's/(F|f)igure [0-9]*/Figure X/g' -e 's/(P|p)icture [0-9]*/Picture X/g' -e 's/(I|i)mage [0-9]*/Image X/g' -e "s/\"/'/g" -e '/^[[:space:]]*$/d' -e 's/^[[:space:]]*//g' -e '/^---$/d' -e 's/  */ /g' "$f" | sed -r -e$'s/[^[:print:]\t]/ /g' > "train_extracted_raw_data/${filename%.*}_clean.txt"
                #echo "<EOF>" >> "train_extracted_raw_data/${filename%.*}_clean.txt"
	fi
	let count=count+1
done

let count=0
for f in "train_extracted_raw_data"/*
do
        filename="$(basename $f)"
        if [[ $filename == *_questions_solutions.txt ]]
        then
                echo "Cleaning train file $filename ..."
		sed -r -e 's/,//g' -e 's/Correct answer:/\nCorrect answer:/g' -e 's/\((Pages|Slides): [0-9, -]+\) \([0-9.]+ points\)//g' -e 's/- End of (Midterm|Final) Exam Solutions -//g' -e 's/(F|f)igure[[:space:]]*[0-9]*\./Figure X\./g' -e 's/(P|p)icture[[:space:]]*[0-9]*\./Picture X\./g' -e 's/(I|i)mage[[:space:]]*[0-9]*\./Image X\./g' -e 's/\s([0-9]+\.)/\n\n\1/g' "$f" | sed -r -e 's/Figure [0-9]*: [^\(\)]*//g' -e 's/(F|f)igure[[:space:]]*[0-9]*/Figure X /g' -e 's/(P|p)icture[[:space:]]*[0-9]*/Picture X /g' -e 's/(I|i)mage[[:space:]]*[0-9]*/Image X /g' | sed -rn 'H; ${x; s/([0-9]*\n\n|).?(Fall|Spring|Summer|Winter) [0-9][0-9][0-9][0-9]\n\nCISC [0-9][0-9][0-9][0-9] [A-Za-z0-9]* (Midterm|Final) Solutions\n\n(CUNY |)Brooklyn College//g; p}' | sed -rn 'H; ${x; s/\n(Midterm|Final) Exam Solutions//g; p}' | sed -r -e 's/\s([0-9]+\.)/\n\1/g' -e '/^.* - Short Answer/d' -e '/^Extra Credit$/d' -e '/^Updated: /d' -e '/^[0-9]*$/d' -e 's/  */ /g' -e "s/\"/'/g" -e 's/^(Fall|Spring|Summer|Winter) [0-9][0-9][0-9][0-9]$//g' -e 's/^CISC [0-9][0-9][0-9][0-9] [A-Za-z0-9]* (Midterm|Final)(| Solutions)$//g' -e 's/^(CUNY |)Brooklyn College$//g' -e 's/^Word$//g' -e 's/^PowerPoint$//g' -e 's/^[[:space:]]*//g' -e '/^[[:space:]]*$/d' -e 's/^(Fall|Spring|Summer|Winter) [0-9][0-9][0-9][0-9]\s*$//g' -e 's/^CISC [0-9][0-9][0-9][0-9] [A-Za-z0-9]* (Midterm|Final)(| Solutions)\s*$//g' -e 's/^(CUNY |)Brooklyn College\s*$//g' -e 's/  */ /g' > "train_extracted_raw_data/${filename%.*}_clean.txt"
		#echo "<EOF>" >> "train_extracted_raw_data/${filename%.*}_clean.txt"
        fi
        let count=count+1
done

let count=0
for f in "test_extracted_raw_data"/*
do
        filename="$(basename $f)"
        if [[ $filename == *_student_answers.txt ]]
        then
		echo "Cleaning test file $filename ..."
		sed --regexp-extended -e 's/([0-9]+)\./\1\)/g' -e 's/,//g' -e 's|Type your answer to question [0-9]+ here.||g' -e '/^FieldType: /d' -e 's/^FieldName: ([0-9]+)$/\1\. /g' -e '/^FieldFlags: /d' -e '/^FieldJustification: /d' -e 's|^FieldValue: ||g' -e 's/(F|f)igure [0-9]*/Figure X/g' -e 's/(P|p)icture [0-9]*/Picture X/g' -e 's/(I|i)mage [0-9]*/Image X/g' -e '/^[[:space:]]*$/d' -e 's/^[[:space:]]*//g' -e "s/\"/'/g" -e '/^---$/d' -e 's/  */ /g' "$f" | sed -r -e$'s/[^[:print:]\t]/ /g' > "test_extracted_raw_data/${filename%.*}_clean.txt"
		#echo "<EOF>" >> "test_extracted_raw_data/${filename%.*}_clean.txt"
        fi
	let count=count+1
done

let count=0
for f in "test_extracted_raw_data"/*
do
        filename="$(basename $f)"
        if [[ $filename == *_questions_solutions.txt ]]
        then
                echo "Cleaning test file $filename ..."
                sed -r -e 's/,//g' -e 's/Correct answer:/\nCorrect answer:/g' -e 's/\((Pages|Slides): [0-9, -]+\) \([0-9.]+ points\)//g' -e 's/- End of (Midterm|Final) Exam Solutions -//g' -e 's/(F|f)igure[[:space:]]*[0-9]*\./Figure X\./g' -e 's/(P|p)icture[[:space:]]*[0-9]*\./Picture X\./g' -e 's/(I|i)mage[[:space:]]*[0-9]*\./Image X\./g' -e 's/\s([0-9]+\.)/\n\n\1/g' "$f" | sed -r -e 's/Figure [0-9]*: [^\(\)]*//g' -e 's/(F|f)igure[[:space:]]*[0-9]*/Figure X /g' -e 's/(P|p)icture[[:space:]]*[0-9]*/Picture X /g' -e 's/(I|i)mage[[:space:]]*[0-9]*/Image X /g' | sed -rn 'H; ${x; s/([0-9]*\n\n|).?(Fall|Spring|Summer|Winter) [0-9][0-9][0-9][0-9]\n\nCISC [0-9][0-9][0-9][0-9] [A-Za-z0-9]* (Midterm|Final) Solutions\n\n(CUNY |)Brooklyn College//g; p}' | sed -rn 'H; ${x; s/\n(Midterm|Final) Exam Solutions//g; p}' | sed -r -e 's/\s([0-9]+\.)/\n\1/g' -e '/^.* - Short Answer/d' -e '/^Extra Credit$/d' -e '/^Updated: /d' -e '/^[0-9]*$/d' -e 's/  */ /g' -e "s/\"/'/g" -e 's/^(Fall|Spring|Summer|Winter) [0-9][0-9][0-9][0-9]$//g' -e 's/^CISC [0-9][0-9][0-9][0-9] [A-Za-z0-9]* (Midterm|Final)(| Solutions)$//g' -e 's/^(CUNY |)Brooklyn College$//g' -e 's/^Word$//g' -e 's/^PowerPoint$//g' -e 's/^[[:space:]]*//g' -e '/^[[:space:]]*$/d' -e 's/^(Fall|Spring|Summer|Winter) [0-9][0-9][0-9][0-9]\s*$//g' -e 's/^CISC [0-9][0-9][0-9][0-9] [A-Za-z0-9]* (Midterm|Final)(| Solutions)\s*$//g' -e 's/^(CUNY |)Brooklyn College\s*$//g' -e 's/  */ /g' > "test_extracted_raw_data/${filename%.*}_clean.txt"
		#echo "<EOF>" >> "test_extracted_raw_data/${filename%.*}_clean.txt"
        fi
        let count=count+1
done

# The last part of this script will create a CSV file that will contain information about the exam question types (and the correct answer thereto) and a CSV file that will contain student answers.

# Creating a folder that will hold student answers, sorted by question type:
mkdir -p collected_answers
mkdir -p collected_answers/train
mkdir -p collected_answers/test

# Creating a dict that maps question text to its question ID:
declare -A question_to_id_dict

# Creating variables that will hold substrings of interest:
question_text="X"
solution_text="Y"
answer_text="Z"

# Creating a counter of question IDs:
let question_id_counter=0

for f in "train_extracted_raw_data"/*
do
        questions_file="$(basename $f)"
        if [[ $questions_file == *_questions_solutions_clean.txt ]]
        then
		let count=0
		let count_plus_1=1
		student_num=$(echo $questions_file | sed 's/_questions_solutions_clean.txt//g')
		answers_file="${student_num}_student_answers_clean.txt"
		echo "Extracting clean training questions and answers from $questions_file and $answers_file ..."
		while :
		do
			let count=count+1
			let count_plus_1=count_plus_1+1
			question_text=$(awk 'sub(/.*^'"$count"'\. */,""){f=1} f{if ( sub(/ *Correct answer:.*/,"") ) f=0; print}' "train_extracted_raw_data/$questions_file" | tr '\n' ' ' | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g' -e 's/  */ /g')
			solution_text=$(awk 'sub(/.*^'"$count"'\. */,""){f=1} f{if ( sub(/ *^'"$count_plus_1"'\. .**/,"") ) f=0; print}' "train_extracted_raw_data/$questions_file" | sed '1,/Correct answer:/ {/Correct answer:/!d; s/Correct answer: *//;}' | tr '\n' ' ' | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g' -e 's/  */ /g')
			answer_text=$(awk 'sub(/.*^'"$count"'\. */,""){f=1} f{if ( sub(/ *^'"$count_plus_1"'\. .**/,"") ) f=0; print}' "train_extracted_raw_data/$answers_file" | tr '\n' ' ' | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g' -e 's/  */ /g')

			if [ -z "$solution_text" ]
                        then
                            break
                        fi

			# Put the question in the dictionary:
			if [[ ! -v question_to_id_dict["$question_text,$solution_text"] ]]
			then
				let question_id_counter=question_id_counter+1
				question_to_id_dict["$question_text,$solution_text"]="q_$question_id_counter"
				echo -n "" > collected_answers/train/"q_${question_id_counter}.txt"
			fi

			curr_value=${question_to_id_dict["$question_text,$solution_text"]}
			echo "${student_num}-${curr_value},${answer_text},${curr_value},correct" >> collected_answers/train/${curr_value}.txt

		done
	fi
done

for f in "test_extracted_raw_data"/*
do
        questions_file="$(basename $f)"
        if [[ $questions_file == *_questions_solutions_clean.txt ]]
        then
		let count=0
		let count_plus_1=1
		student_num=$(echo $questions_file | sed 's/_questions_solutions_clean.txt//g')
		answers_file="${student_num}_student_answers_clean.txt"
		#answers_file="$(echo $questions_file | sed 's/_questions_solutions_clean.txt//g')_student_answers_clean.txt"
		echo "Extracting clean test questions and answers from $questions_file and $answers_file ..."
		while :
		do
			let count=count+1
			let count_plus_1=count_plus_1+1
			question_text=$(awk 'sub(/.*^'"$count"'\. */,""){f=1} f{if ( sub(/ *Correct answer:.*/,"") ) f=0; print}' "test_extracted_raw_data/$questions_file" | tr '\n' ' ' | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g' -e 's/  */ /g')
			solution_text=$(awk 'sub(/.*^'"$count"'\. */,""){f=1} f{if ( sub(/ *^'"$count_plus_1"'\. .**/,"") ) f=0; print}' "test_extracted_raw_data/$questions_file" | sed '1,/Correct answer:/ {/Correct answer:/!d; s/Correct answer: *//;}' | tr '\n' ' ' | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g' -e 's/  */ /g')
			answer_text=$(awk 'sub(/.*^'"$count"'\. */,""){f=1} f{if ( sub(/ *^'"$count_plus_1"'\. .**/,"") ) f=0; print}' "test_extracted_raw_data/$answers_file" | tr '\n' ' ' | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//g' -e 's/  */ /g')

			if [ -z "$solution_text" ]
                        then
                            break
                        fi

			# Put the question in the dictionary:
			if [[ ! -v question_to_id_dict["$question_text,$solution_text"] ]]
			then
				let question_id_counter=question_id_counter+1
				question_to_id_dict["$question_text,$solution_text"]="q_$question_id_counter"
				echo -n "" > collected_answers/test/"q_${question_id_counter}.txt"
			fi

			curr_value=${question_to_id_dict["$question_text,$solution_text"]}
			echo "${student_num}-${curr_value},${answer_text},${curr_value},correct" >> collected_answers/test/${curr_value}.txt
		done
	fi
done

echo "Sorting questions alphabetically ..."
# Echo the keys, each on a separate line, into a file:
echo "" > "file_containing_detected_question_types.txt"
for key in "${!question_to_id_dict[@]}"; do
    echo "$key" >> "file_containing_detected_question_types.txt"
done

# Sorting the file:
sort file_containing_detected_question_types.txt > question_types_sorted.txt

# Getting all the keys back and sorting them:
IFS=$'\n' read -d '' -r -a keys < question_types_sorted.txt

# Create empty CSV files: questions.csv and student_answers.csv
mkdir -p csv_data_files
mkdir -p csv_data_files/train
mkdir -p csv_data_files/test
echo "a_id,a_text,q_id,score" > csv_data_files/train/student_answers.csv
echo "a_id,a_text,q_id,score" > csv_data_files/test/student_answers.csv
echo "q_id,q_text,correct_a_text" > csv_data_files/questions.csv

echo "Sorting student answers based on questions ..."
for((i=0;i<${#keys[@]};i++))
do
	my_key="${keys[$i]}"
	question_id="${question_to_id_dict[$my_key]}"
	#echo "${my_key}: ${question_to_id_dict[$my_key]}"
	if [[ -f collected_answers/train/${question_id}.txt ]]
	then
		cat collected_answers/train/${question_id}.txt >> csv_data_files/train/student_answers.csv
	fi
	if [[ -f collected_answers/test/${question_id}.txt ]]
	then
		cat collected_answers/test/${question_id}.txt >> csv_data_files/test/student_answers.csv
	fi
	echo "${question_id},$my_key" >> csv_data_files/questions.csv
done

echo "${BLU_BG}${WHITE}NOTE${NC} The following files were created:\n  1.  ${BRWN_BG}${BLACK}questions.csv${NC},\n  2.${BRWN_BG}${BLACK}train/student_answers.csv${NC}, and\n  3.${BRWN_BG}${BLACK}test/student_answers.csv${NC}.\nYou can find them in the ${BRWN_BG}${BLACK}csv_data_files${NC} folder."

echo '---------------------------------------'
echo "Done!"

# Copyright (C) Miriam Briskman 2024
# For non-commercial use only