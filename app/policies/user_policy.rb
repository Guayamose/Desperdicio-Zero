class UserPolicy < ApplicationPolicy
  def index?
    system_admin?
  end

  def show?
    system_admin?
  end

  def create?
    system_admin?
  end

  def update?
    system_admin?
  end

  def block?
    system_admin?
  end

  class Scope < Scope
    def resolve
      system_admin? ? scope.all : scope.none
    end
  end
end
