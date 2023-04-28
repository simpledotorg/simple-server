class Dashboard::Card::TooltipComponent < ApplicationComponent
  attr_reader :definitions

  def initialize(definitions)
    @definitions = definitions
  end

  def render?
    definitions.present?
  end

  def tooltip_content
    return definitions.to_s if !definitions.is_a? Hash
    definitions.collect do |name, description|
      
      if name == "divider"
        tag :hr, class: 'bg-white o-65 mt-4px mb-4px'
      else
        content_tag :p, class: "mb-4px" do
          if name == "Note"
            content_tag(:i, description)
          elsif name == ""
            description
          else
            content_tag(:strong, name) << ": #{description}"
          end
        end
      end  
        # elsif name == "divider"
        #   content_tag :hr, class: 'bg-white mt-4px mb-4px'
        
        # else
          
        
      # end
    end.join
  end
end
