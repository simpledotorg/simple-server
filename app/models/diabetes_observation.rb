class DiabetesObservation < ApplicationRecord

  enum observation_type: {
    random: 'random',
    post_prandial: 'post_prandial',
    fasting: 'fasting'
  }, _prefix: true

end