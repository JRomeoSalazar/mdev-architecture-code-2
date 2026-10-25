# Gherkin es un lenguaje de dominio específico (DSL) legible para humanos
# que se utiliza para definir el comportamiento de un sistema 
# a través de escenarios claros y estructurados, conectando a 
# perfiles de negocio, desarrollo y calidad.
# https://www.qamakers.com/p/guia-completa-de-cucumber-y-gherkin.html

Feature: Borrow a book

  Scenario: A standard member borrows an available book
    Given a book with one available copy
    And an active standard member with no active loans
    When the member borrows the book on 2026-09-01
    Then the loan is accepted
    And its due date is 2026-09-15
    And the book has no available copies
    And the member has one active loan

  Scenario: A suspended member tries to borrow a book
    Given a book with one available copy
    And a suspended member
    When the member tries to borrow the book
    Then the loan is rejected because the member is suspended

  Scenario: A book has no available copies
    Given a book with no available copies
    And an active member below the loan limit
    When the member tries to borrow the book
    Then the loan is rejected because the book is unavailable
