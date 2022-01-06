# frozen_string_literal: true

module BustCache
  def bust_cache?
    RequestStore.store[:bust_cache]
  end
end
