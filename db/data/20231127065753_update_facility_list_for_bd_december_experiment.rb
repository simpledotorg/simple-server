# frozen_string_literal: true

class UpdateFacilityListForBdDecemberExperiment < ActiveRecord::Migration[6.1]
  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    facilities = {
      sylhet: %w[uhc-osmaninagar uhc-taherpur],
      rajshahi: %w[atgharia-upazila-health-complex uhc-bera uhc-faridpur uhc-sujanagar-4b973cb1-d584-4100-91ca-778f218b502],
      netrokona: %w[uhc-barhatta uhc-durgapur-dbd6efea-8950-410e-abc3-ed9a329fb9d3 uhc-kalmakanda uhc-kendua uhc-khaliajuri uhc-madan uhc-purbadhala],
      sherpur: %w[uhc-jhenaigati uhc-nakhla uhc-nalitabari uhc-sribordi],
      jamalpur: %w[uhc-bakshiganj uhc-dewanganj uhc-islampur uhc-madarganj uhc-melandah],
      feni: %w[uhc-chhagalniya uhc-daganbhuiya uhc-fulgazi uhc-parsuram uhc-sonagazi],
      chattogram: %w[uhc-anwara uhc-banshkhali uhc-boalkhali uhc-chandanaish uhc-fatikchori uhc-hathazari uhc-karnaphuli uhc-lohagara uhc-mirsharai uhc-patiya uhc-rangunia uhc-raozan uhc-sandwip uhc-satkania uhc-sitakunda],
      bandarban: ["uhc-lama"],
      barishal: %w[uhc-kathalia-86845c14-b23d-4578-820a-63eb9628422a uhc-nalchity-97cb9397-8ca7-4edb-81ae-2ac8fb1ea93a uhc-rajapur-40d0e15a-37c4-4833-8f55-446bb210c457 uhc-agailjhara uhc-bakerganj uhc-gaurnadi uhc-hijla uhc-mehendiganj uhc-muladi uhc-wazirpur uhc-babuganj]
    }.values.reduce(:+)
    updated_region_filters = {"facilities" => {"include" => facilities}}

    Experimentation::Experiment.find_by_name("Current Patient December 2023")
      &.update!(filters: updated_region_filters)
    Experimentation::Experiment.find_by_name("Stale Patient December 2023")
      &.update!(filters: updated_region_filters)
  end

  def down
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    old_region_filters = {"facilities" =>
                            {"include" => %w[uhc-agailjhara uhc-babuganj-facility uhc-bakerganj uhc-hijla uhc-mehendiganj
                              uhc-muladi uhc-wazirpur uhc-kathalia-86845c14-b23d-4578-820a-63eb9628422a uhc-nalchity-97cb9397-8ca7-4edb-81ae-2ac8fb1ea93a
                              uhc-rajapur-40d0e15a-37c4-4833-8f55-446bb210c457 thc-tejgaon-sadar uhc-dhamrai uhc-dohar uhc-nawabganj uhc-damuddya
                              uhc-goshairhat uhc-sreenagar uhc-tongibari uhc-sirajdikhan uhc-hathazari uhc-fatikchori uhc-anwara uhc-satkania
                              uhc-lohagara uhc-patiya uhc-rangunia uhc-sitakunda uhc-chandanaish uhc-raozan uhc-banshkhali uhc-boalkhali uhc-karnaphuli
                              uhc-mirsharai uhc-sandwip uhc-fulgazi uhc-parsuram uhc-daganbhuiya uhc-sonagazi uhc-chhagalniya uhc-atpara uhc-barhatta
                              uhc-kalmakanda uhc-kendua uhc-khaliajuri uhc-madan uhc-mohanganj uhc-purbadhala uhc-durgapur-dbd6efea-8950-410e-abc3-ed9a329fb9d3
                              uhc-belkuchi uhc-chowhali uhc-kamarkhanda uhc-kazipur uhc-shahzadpur uhc-tarash uhc-ullapara uhc-bera uhc-bhangura
                              uhc-faridpur uhc-iswardi uhc-santhia uhc-chatmohar uhc-sujanagar-4b973cb1-d584-4100-91ca-778f218b502e atgharia-upazila-health-complex
                              uhc-islampur uhc-melandah uhc-sarishabari uhc-dewanganj uhc-bakshiganj uhc-madarganj uhc-jhenaigati uhc-nalitabari uhc-nakhla
                              uhc-sribordi]}}

    Experimentation::Experiment.find_by_name("Current Patient December 2023")
      &.update!(filters: old_region_filters)
    Experimentation::Experiment.find_by_name("Stale Patient December 2023")
      &.update!(filters: old_region_filters)
  end
end
