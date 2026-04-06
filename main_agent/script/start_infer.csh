set DATASET = $argv[1]
set MODEL_PATH = $argv[2]
echo $DATASET
echo $MODEL_PATH
set PYTHON_VENV1_DIR = /proj/cad_ml/kheloue/ML_work/env/mlenv-py3.8.0-20201112/bin/python3

$PYTHON_VENV1_DIR /tools/aticad/1.0/flow/TileBuilder/supra/scripts/ml/ml_utility/ml_utility.py \
    --dataset $DATASET \
    --classification \
    --infer \
    --infer_log $DATASET.infer.log \
    --infer_output $DATASET.infer.output.csv \
    --load_model_from $MODEL_PATH
#    --predict_proba
