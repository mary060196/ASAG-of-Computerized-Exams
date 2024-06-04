import csv

TRAIN_FILE_PATH = ['./csv_data_files/train/student_answers_mini.csv']
TEST_FILE_PATH = ['./csv_data_files/test/student_answers_mini.csv']

SEP_TOKEN = '[SEP]'
CLS_TOKEN = '[CLS]'

hyperparameters = dict(
    train_id="1024_SFRN_sci_5way_test0",
    model_name="bert-base-uncased",
    num_labels = 2,
    max_length = 128,
    random_seed=23, # 23， 
    data_split=0.2,
    lr=1e-5,
    epochs=25,
    weight_decay=0.01,
    GRADIENT_ACCUMULATION_STEPS=1,
    max_norm = 1, 
    WARMUP_STEPS=0.2,
    hidden_dropout_prob=0.2,
    # model
    hidden_dim=768, # 768
    mlp_hidden=128,
    )
# wandb config

config_dictionary = dict(
    params=hyperparameters,
    )

# Get the questions and the correct answers (= 'rubrics') from the
#    './csv_data_files/questions.csv' file:
file_data = []
q_text_dict = dict()
q_rubric_dict = dict()
with open("./csv_data_files/questions.csv") as csvfile:
    csv_reader = csv.reader(csvfile)
    file_header = next(csv_reader)
    for row in csv_reader:
        file_data.append(row)
    for row in file_data:
        q_text_dict[row[0]] = row[1]
        q_rubric_dict[row[0]] = [row[1]]