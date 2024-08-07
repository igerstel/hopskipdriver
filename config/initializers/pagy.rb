require 'pagy/extras/metadata'
require 'pagy/extras/overflow'

Pagy::DEFAULT[:limit] = 10
Pagy::DEFAULT[:page]  = 1
Pagy::DEFAULT[:overflow] = :last_page
