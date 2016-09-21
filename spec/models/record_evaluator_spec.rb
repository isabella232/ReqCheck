require 'rails_helper'

RSpec.describe RecordEvaluator, type: :model do
  include PatientHelper

  before(:all) do
    FactoryGirl.create(:seed_full_antigen_xml)
  end
  after(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end

  let(:test_patient) { valid_5_year_test_patient }
  let(:record_evaluator) { RecordEvaluator.new(patient: test_patient) }

  describe 'validations' do
    it 'requires a patient object' do
      expect{RecordEvaluator.new}.to raise_exception(ArgumentError)
    end
  end

  describe 'relationships' do
    let(:record_evaluator) { RecordEvaluator.new(patient: test_patient) }

    it 'creates a patients antigen_administered_records' do
      expect(record_evaluator.antigen_administered_records.length).to eq(40)
      expect(
        record_evaluator.antigen_administered_records.first.class.name
      ).to eq('AntigenAdministeredRecord')
    end
  end

  describe '#get_antigens' do
    it 'pulls all antigens from the database' do
      expect(record_evaluator.get_antigens.length).to eq(17)
    end
    it 'pulls only unique antigens from the database' do
      expect(record_evaluator.get_antigens.length).to eq(17)
      FactoryGirl.create(:antigen, target_disease: 'polio')
      expect(record_evaluator.get_antigens.length).to eq(17)
    end
  end

  describe '#create_all_antigen_evaluators' do
    let(:test_aars) do
      AntigenAdministeredRecord.create_records_from_vaccine_doses(
        test_patient.vaccine_doses
      )
    end
    let(:record_evaluator) { RecordEvaluator.new(patient: test_patient) }

    it 'creates an antigen evaluators for each antigen' do
      antigens = Antigen.all
      record_evaluator.create_all_antigen_evaluators(
        test_patient,
        antigens,
        test_aars
      )
      expect(record_evaluator.antigen_evaluators.length).to eq(17)
      expect(record_evaluator.antigen_evaluators.first.class.name)
        .to eq('AntigenEvaluator')
    end
  end


  describe '#record_evaluation' do
    it 'sets a record status to the evaluation' do
      record_evaluator = RecordEvaluator.new(
        patient: valid_2_year_test_patient
      )
      expect(record_evaluator.record_status).to eq('complete')
    end
    it 'sets a vaccine_group_evaluations to the evaluation' do
      record_evaluator = RecordEvaluator.new(
        patient: valid_2_year_test_patient
      )
      expect(record_evaluator.vaccine_group_evaluations).to eq(
        {
          :"dtap/tdap/td" => "complete",
          :"hep a" => "complete",
          :"zoster " => "complete",
          :hepb => "complete",
          :hib => "not_complete",
          :hpv => "complete",
          :influenza => "not_complete",
          :mcv => "complete",
          :mmr => "complete",
          :pneumococcal => "complete",
          :polio => "complete",
          :rotavirus => "complete",
          :varicella => "complete"
        }
      )
      expect(false).to be(true) # NEED TO FIGURE OUT HOW TO UNIFY ALL OF THE KEYS TO BE OF THE SAME FORMAT (SOME ARE STRINGS, OTHERS ARE NOT)
    end
    context 'with a 2 year old patient' do
      it 'returns complete for an up to date patient' do
        record_evaluator = RecordEvaluator.new(
          patient: valid_2_year_test_patient
        )
        expect(record_evaluator.record_status).to eq('complete')
      end
      it 'returns not_complete for a not up to date patient' do
        new_test_patient = valid_2_year_test_patient
        VaccineDose.destroy_all(cvx_code: 94)

        vaccines = new_test_patient.vaccine_doses
        mmrv_vaccines = vaccines.select do |vaccine_dose|
          vaccine_dose.cvx_code == 94
        end
        expect(mmrv_vaccines).to eq([])
        record_evaluator = RecordEvaluator.new(
          patient: new_test_patient
        )
        expect(record_evaluator.record_status).to eq('not_complete')
      end
    end
    context 'with a 5 year old patient' do
      it 'returns complete for an up to date patient' do
        record_evaluator = RecordEvaluator.new(
          patient: valid_5_year_test_patient
        )
        expect(record_evaluator.record_status).to eq('complete')
      end
      it 'returns not_complete for a not up to date patient' do
        new_test_patient = valid_5_year_test_patient
        VaccineDose.destroy_all(cvx_code: 110)

        vaccines = new_test_patient.vaccine_doses
        deleted_vaccines = vaccines.select do |vaccine_dose|
          vaccine_dose.cvx_code == 110
        end
        expect(deleted_vaccines).to eq([])
        record_evaluator = RecordEvaluator.new(
          patient: new_test_patient
        )
        expect(record_evaluator.record_status).to eq('not_complete')
      end
    end
  end
end



# context 'with a child aged < 1 years' do
#   let(:test_patient_baby) { FactoryGirl.create(:patient_with_profile, dob: 10.months.ago) }

# end
# context 'with a child aged ~= 5 years' do
#   let(:test_patient_child) { FactoryGirl.create(:patient_with_profile, dob: 58.months.ago) }

# end
# context 'with a child aged ~= 12 years' do
#   let(:test_patient_child) { FactoryGirl.create(:patient_with_profile, dob: 12.years.ago) }

# end
# context 'with a child aged ~= 18 years' do
#   let(:test_patient_child) { FactoryGirl.create(:patient_with_profile, dob: 12.years.ago) }

# end
