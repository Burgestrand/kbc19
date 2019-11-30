class StaticPageController < ApplicationController
  def home
    children = Child.all

    render :home, locals: {
      children: children
    }
  end
end
