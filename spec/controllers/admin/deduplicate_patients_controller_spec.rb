require "rails_helper"

RSpec.describe Admin::DeduplicatePatientsController, type: :controller do
  describe "#show" do
    it "shows patients accessible by the user" do
      patient = create(:patient, full_name: "Patient one")
      patient_passport_id = patient.business_identifiers.first.identifier

      patient_dup = create(:patient, full_name: "Patient one dup")
      patient_dup.business_identifiers.first.update(identifier: patient_passport_id)

      admin = create(:admin, :manager, :with_access, resource: patient.assigned_facility)
      sign_in(admin.email_authentication)

      get :show

      expect(assigns(:patients)).to contain_exactly(patient, patient_dup)
    end

    it "omits patients not accessible by the user" do
      patient = create(:patient, full_name: "Patient one")
      patient_passport_id = patient.business_identifiers.first.identifier

      patient_dup = create(:patient, full_name: "Patient one dup")
      patient_dup.business_identifiers.first.update(identifier: patient_passport_id)

      admin = create(:admin, :manager, :with_access, resource: create(:facility))
      sign_in(admin.email_authentication)

      get :show

      expect(assigns(:patients)).to be_empty
    end

    it "returns unauthorized when the user does not have any managerial roles" do
      admin = create(:admin, :viewer_all)
      sign_in(admin.email_authentication)

      get :show
      expect(response.status).to eq(302)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end

    context "when patient_deduplication_filter feature flag is enabled" do
      let(:organization) { create(:organization) }
      let(:facility_group) { create(:facility_group, organization: organization) }
      let(:district) { facility_group.region.parent }
      let(:facility1) { create(:facility, facility_group: facility_group) }
      let(:facility2) { create(:facility, facility_group: facility_group) }
      let(:admin) { create(:admin, :manager, :with_access, resource: organization) }

      before do
        sign_in(admin.email_authentication)
        Flipper.enable(:patient_deduplication_filter, admin)
      end

      it "sets filter options when feature flag is enabled" do
        get :show

        expect(assigns(:districts)).to be_present
        expect(assigns(:selected_district)).to be_present
      end

      it "populates accessible districts" do
        facility1
        get :show

        expect(assigns(:districts)).to include(district)
      end

      it "filters patients by selected district" do
        patient1 = create(:patient, full_name: "Patient one", assigned_facility: facility1)
        patient1_passport_id = patient1.business_identifiers.first.identifier

        patient1_dup = create(:patient, full_name: "Patient one dup", assigned_facility: facility1)
        patient1_dup.business_identifiers.first.update(identifier: patient1_passport_id)

        other_facility_group = create(:facility_group, organization: organization)
        other_facility = create(:facility, facility_group: other_facility_group)

        patient2 = create(:patient, full_name: "Patient two", assigned_facility: other_facility)
        patient2_passport_id = patient2.business_identifiers.first.identifier

        patient2_dup = create(:patient, full_name: "Patient two dup", assigned_facility: other_facility)
        patient2_dup.business_identifiers.first.update(identifier: patient2_passport_id)

        get :show, params: {district_slug: district.slug}

        expect(assigns(:patients)).to include(patient1, patient1_dup)
        expect(assigns(:patients)).not_to include(patient2, patient2_dup)
      end

      it "filters patients by selected facility" do
        patient1 = create(:patient, full_name: "Patient one", assigned_facility: facility1)
        patient1_passport_id = patient1.business_identifiers.first.identifier

        patient1_dup = create(:patient, full_name: "Patient one dup", assigned_facility: facility1)
        patient1_dup.business_identifiers.first.update(identifier: patient1_passport_id)

        patient2 = create(:patient, full_name: "Patient two", assigned_facility: facility2)
        patient2_passport_id = patient2.business_identifiers.first.identifier

        patient2_dup = create(:patient, full_name: "Patient two dup", assigned_facility: facility2)
        patient2_dup.business_identifiers.first.update(identifier: patient2_passport_id)

        get :show, params: {district_slug: district.slug, facility_id: facility1.id}

        expect(assigns(:patients)).to include(patient1, patient1_dup)
        expect(assigns(:patients)).not_to include(patient2, patient2_dup)
      end

      it "populates facilities for the selected district" do
        facility1
        facility2
        get :show, params: {district_slug: district.slug}

        expect(assigns(:facilities)).to include(facility1, facility2)
      end

      it "sets the selected facility when facility_id param is present" do
        facility1
        get :show, params: {district_slug: district.slug, facility_id: facility1.id}

        expect(assigns(:selected_facility)).to eq(facility1)
      end
    end

    context "when patient_deduplication_filter feature flag is disabled" do
      let(:admin) { create(:admin, :manager, :with_access, resource: create(:facility)) }

      before do
        sign_in(admin.email_authentication)
        Flipper.disable(:patient_deduplication_filter)
      end

      it "does not set filter options" do
        get :show

        expect(assigns(:districts)).to be_nil
        expect(assigns(:selected_district)).to be_nil
        expect(assigns(:facilities)).to be_nil
      end

      it "shows all accessible duplicate patients without filtering" do
        facility = admin.accessible_facilities(:manage).first
        patient = create(:patient, full_name: "Patient one", assigned_facility: facility)
        patient_passport_id = patient.business_identifiers.first.identifier

        patient_dup = create(:patient, full_name: "Patient one dup", assigned_facility: facility)
        patient_dup.business_identifiers.first.update(identifier: patient_passport_id)

        get :show

        expect(assigns(:patients)).to contain_exactly(patient, patient_dup)
      end
    end
  end

  describe "#merge" do
    it "returns unauthorized when none of the patient IDs is accessible by the user" do
      patients = [create(:patient, full_name: "Patient one"), create(:patient, full_name: "Patient two")]
      admin = create(:admin, :manager, :with_access, resource: create(:facility))
      sign_in(admin.email_authentication)

      post :merge, params: {duplicate_patients: patients.map(&:id)}

      expect(response.status).to eq(401)
    end

    it "handles any errors with merge" do
      admin = create(:admin, :power_user)
      sign_in(admin.email_authentication)

      allow_any_instance_of(PatientDeduplication::Deduplicator).to receive(:errors).and_return(["Some error"])
      patients = [create(:patient, full_name: "Patient one"), create(:patient, full_name: "Patient two")]

      post :merge, params: {duplicate_patients: patients.map(&:id)}
      expect(flash.alert).to be_present
      expect(Patient.count).to eq 2
    end
  end
end
