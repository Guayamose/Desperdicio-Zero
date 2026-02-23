class ProductPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def create?
    user.present?
  end

  def update?
    user.present?
  end

  class Scope < Scope
    def resolve
      user.present? ? scope.all : scope.none
    end
  end
end
