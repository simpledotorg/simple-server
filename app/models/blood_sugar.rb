class BloodSugar < ApplicationRecord

  enum blood_sugar_type: {
    random: 'random',
    post_prandial: 'post_prandial',
    fasting: 'fasting'
  }, _prefix: true

end