Temping.create :person do
  with_columns do |t|
    t.string :first_name
    t.string :last_name, null: false
    # Need some sort of DB contraint or
    # ActiveRecord::Base.connection.data_source_exists? is false for some reason,
    t.string :phone_number
  end
end

RSpec.describe Sanitization do
  it "has a version number" do
    expect(Sanitization::VERSION).not_to be nil
  end

  describe "before_sanitization hook" do
    context "for a model that uses sanitization" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, nullify: true
          before_sanitization :change_name

          def change_name
            self.first_name = "Jane"
          end
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "John", last_name: "anything") }

      it "calls the callback" do
        expect(person.first_name).to eq("Jane")
      end
    end

    context "for a model that doesn't call `sanitize`" do
      it "raises an exception" do
        expect {
          person_class = Class.new(Person) do
            before_sanitization :change_name

            def change_name
              self.first_name = "Jane"
            end
          end
          stub_const('Person', person_class)
        }.to raise_error(NoMethodError, /undefined method `before_sanitization'/)
      end
    end
  end

  describe "after_sanitization hook" do
    context "for a model that uses sanitization" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, nullify: true
          after_sanitization :change_name

          def change_name
            self.first_name = "Jane"
          end
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "    ", last_name: "anything") }

      it "calls the callback" do
        expect(person.first_name).to eq("Jane")
      end
    end

    context "for a model that doesn't call `sanitize`" do
      it "raises an exception" do
        expect {
          person_class = Class.new(Person) do
            after_sanitization :change_name

            def change_name
              self.first_name = "Jane"
            end
          end
          stub_const('Person', person_class)
        }.to raise_error(NoMethodError, /undefined method `after_sanitization'/)
      end
    end
  end

  describe ":case" do
    context "with case set to :downcase" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, case: :downcase
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "John", last_name: "anything") }

      it "lowercases every character" do
        expect(person.first_name).to eq("john")
      end
    end

    context "with case set to :camelcase" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, case: :camelcase
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "JohnPatrick", last_name: "anything") }

      it "lowercases the first character, and then capitalizes the first character of every subsequent word" do
        expect(person.first_name).to eq("johnPatrick")
      end
    end

    context "with case set to :pascalcase" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, case: :pascalcase
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "john_patrick", last_name: "anything") }

      it "capitalizes the first character of every word and removes underscores" do
        expect(person.first_name).to eq("JohnPatrick")
      end
    end

    context "with case set to :titlecase" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, case: :titlecase
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "john_patrick", last_name: "anything") }

      it "capitalizes the first character of every word and converts underscores to spaces" do
        expect(person.first_name).to eq("John Patrick")
      end
    end

    context "with case set to :upcase" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, case: :upcase
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "John", last_name: "anything") }

      it "capitalizes every character" do
        expect(person.first_name).to eq("JOHN")
      end
    end

    context "with a custom case" do
      before do
        String.class_eval do
          def pipecase
            self.to_s.gsub(/[^0-9a-z]/i, '').upcase.chars.join('|')
          end
        end
        person_class = Class.new(Person) do
          sanitizes :first_name, case: :pipecase
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "john", last_name: "anything") }

      it "runs the custom case conversion" do
        expect(person.first_name).to eq("J|O|H|N")
      end
    end

    context "with a case that isn't defined on String (like snakecase without rails)" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, case: :snakecase
        end
        stub_const('Person', person_class)
      end

      it "raises an exception" do
        expect {
          Person.create(first_name: "JohnPatrick", last_name: "anything")
        }.to raise_error(NoMethodError, /undefined method `snakecase' for.*String/)
      end
    end
  end

  describe ":gsub" do
    context "with nullify set to false" do
      before do
        person_class = Class.new(Person) do
          sanitizes :phone_number, gsub: { pattern: /[^0-9]/, replacement: '' }
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "John", last_name: "anything", phone_number: "+1 (801) 111-3333") }

      it "performs the indicated gsub on the string" do
        expect(person.phone_number).to eq("18011113333")
      end
    end
  end

  describe ":nullify" do
    context "with nullify set to false" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, nullify: false
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "    ", last_name: "anything") }

      it "leaves the value unchanged" do
        expect(person.first_name).to eq("    ")
      end
    end

    context "with nullify set to true" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, nullify: true
        end
        stub_const('Person', person_class)
      end

      context "with a blank value" do
        let!(:person) { Person.create(first_name: "    ", last_name: "anything") }

        it "changes the value to nil" do
          expect(person.first_name).to be_nil
        end
      end

      context "with a present value" do
        let!(:person) { Person.create(first_name: "John", last_name: "anything") }

        it "leaves the value unchanged" do
          expect(person.first_name).to eq("John")
        end
      end
    end
  end

  describe ":remove" do
  end

  describe ":round" do
  end

  describe ":squish" do
    context "with squish set to true" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, squish: true
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "    John    John    ", last_name: "anything") }

      it "removes all whitespace on both ends of the string and changes remaining consecutive whitespace groups into one space each." do
        expect(person.first_name).to eq("John John")
      end
    end

    context "with squish set to false" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, squish: false
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "    John    John    ", last_name: "anything") }

      it "leaves the value unchanged" do
        expect(person.first_name).to eq("    John    John    ")
      end
    end
  end

  describe ":strip" do
    before do
      person_class = Class.new(Person) do
        sanitizes :first_name, strip: true
      end
      stub_const('Person', person_class)
    end

    context "with a value containing leading whitespace" do
      let!(:person) { Person.create(first_name: "    John", last_name: "anything") }

      it "strips the leading whitespace" do
        expect(person.first_name).to eq("John")
      end
    end

    context "with a value containing trailing whitespace" do
      let!(:person) { Person.create(first_name: "John     ", last_name: "anything") }

      it "strips the trailing whitespace" do
        expect(person.first_name).to eq("John")
      end
    end

    context "with a value containing multiple whitespace characters in the middle" do
      let!(:person) { Person.create(first_name: "Jo    hn", last_name: "anything") }

      it "leaves the value unchanged" do
        expect(person.first_name).to eq("Jo    hn")
      end
    end
  end

  describe ":truncate" do
    context "with a number" do
      before do
        person_class = Class.new(Person) do
          sanitizes :first_name, truncate: 4
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "Johnny", last_name: "anything") }

      it "truncates the value at the correct length" do
        expect(person.first_name).to eq("John")
      end
    end
  end
end
