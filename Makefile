VERILATOR ?= verilator
BUILD_DIR ?= build/verilator
M ?= 2
K ?= 3
N ?= 2
MATMUL_OUTDIR ?= generated/matmul
RMSNORM_OUTDIR ?= generated/rmsnorm
SOFTMAX_OUTDIR ?= generated/softmax
N_EMBD ?= 16
VECTOR_SIZE ?= 16
NUM_TOKENS ?= 5
ifeq ($(VCD),1)
VERILATOR_TRACE_FLAGS := --trace
SIM_TRACE_ARGS := +VCD
else
VERILATOR_TRACE_FLAGS :=
SIM_TRACE_ARGS :=
endif

.PHONY: sim-matmul sim-rmsnorm sim-softmax sim-core clean

sim-matmul:
	python scripts/generate_matrix.py --m $(M) --k $(K) --n $(N) --outdir $(MATMUL_OUTDIR)
	mkdir -p $(BUILD_DIR)/matmul_unit_tb
	$(VERILATOR) --binary -sv --timing \
		$(VERILATOR_TRACE_FLAGS) \
		--Mdir $(BUILD_DIR)/matmul_unit_tb \
		--top-module matmul_unit_tb \
		-GM=$(M) -GK=$(K) -GN=$(N) \
		rtl/matmul_unit.sv \
		tb/matmul_unit_tb.sv
	$(BUILD_DIR)/matmul_unit_tb/Vmatmul_unit_tb \
		+MAT_A=$(MATMUL_OUTDIR)/mat_a.mem \
		+MAT_B=$(MATMUL_OUTDIR)/mat_b.mem \
		+MAT_C=$(MATMUL_OUTDIR)/mat_c_expected.mem \
		$(SIM_TRACE_ARGS)

sim-rmsnorm:
	python scripts/generate_rmsnorm.py --n-embd $(N_EMBD) --outdir $(RMSNORM_OUTDIR)
	mkdir -p $(BUILD_DIR)/rmsnorm_tb
	$(VERILATOR) --binary -sv --timing \
		$(VERILATOR_TRACE_FLAGS) \
		--Mdir $(BUILD_DIR)/rmsnorm_tb \
		--top-module rmsnorm_tb \
		-GN_EMBD=$(N_EMBD) \
		rtl/sqrt_engine.sv \
		rtl/rmsnorm.sv \
		tb/rmsnorm_tb.sv
	$(BUILD_DIR)/rmsnorm_tb/Vrmsnorm_tb \
		+INPUT=$(RMSNORM_OUTDIR)/rmsnorm_input.mem \
		+EXPECTED=$(RMSNORM_OUTDIR)/rmsnorm_expected.mem \
		$(SIM_TRACE_ARGS)

sim-softmax:
	python scripts/generate_softmax.py --vector-size $(VECTOR_SIZE) --outdir $(SOFTMAX_OUTDIR)
	mkdir -p $(BUILD_DIR)/softmax_tb
	$(VERILATOR) --binary -sv --timing \
		$(VERILATOR_TRACE_FLAGS) \
		--Mdir $(BUILD_DIR)/softmax_tb \
		--top-module softmax_tb \
		-GVECTOR_SIZE=$(VECTOR_SIZE) \
		-GEXP_INIT_FILE=\"$(SOFTMAX_OUTDIR)/exp_lut.mem\" \
		rtl/softmax.sv \
		tb/softmax_tb.sv
	$(BUILD_DIR)/softmax_tb/Vsoftmax_tb \
		+LOGITS=$(SOFTMAX_OUTDIR)/softmax_logits.mem \
		+EXPECTED=$(SOFTMAX_OUTDIR)/softmax_expected.mem \
		+LUT=$(SOFTMAX_OUTDIR)/exp_lut.mem \
		$(SIM_TRACE_ARGS)

sim-core:
	mkdir -p $(BUILD_DIR)/core_inference_tb
	$(VERILATOR) --binary -sv --timing \
		$(VERILATOR_TRACE_FLAGS) \
		--Mdir $(BUILD_DIR)/core_inference_tb \
		--top-module core_inference_tb \
		-GNUM_TOKENS=$(NUM_TOKENS) \
		rtl/fixed_point_utils.sv \
		rtl/embedding_rom.sv \
		rtl/embedding_lookup.sv \
		rtl/sqrt_engine.sv \
		rtl/rmsnorm.sv \
		rtl/matmul_unit.sv \
		rtl/linear.sv \
		rtl/relu.sv \
		rtl/softmax.sv \
		rtl/attention_score.sv \
		rtl/kv_cache.sv \
		rtl/core_inference.sv \
		tb/core_inference_tb.sv
	$(BUILD_DIR)/core_inference_tb/Vcore_inference_tb \
		+TOKENS=generated/reference/input_tokens.mem \
		$(SIM_TRACE_ARGS)

clean:
	rm -rf build
