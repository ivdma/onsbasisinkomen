class Api::WinnersController < ApplicationController

  #everyone's a winner baby, that's for sure! :)

  def index
    render json: User.select('id,name,avatar').where('winner > 0').order('winner asc')
  	#render json: User.find(:all,:select => 'id,name,avatar', :conditions => 'winner > 0', :order =>  'winner asc')
  end

end