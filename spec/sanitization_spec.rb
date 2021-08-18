Temping.create :person do
  with_columns do |t|
    t.string :first_name
    t.string :last_name, null: false
    # Need some sort of DB contraint or
    # ActiveRecord::Base.connection.data_source_exists? is false for some reason
    t.string :phone_number
    t.string :zip_code
    t.float :income
    t.string :ssn
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
    context "with nullify set to false" do
      before do
        person_class = Class.new(Person) do
          sanitizes :zip_code, remove: "-"
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "John", last_name: "anything", zip_code: "55555-4444-") }

      it "removes the specified value from the string" do
        expect(person.zip_code).to eq("555554444")
      end
    end
  end

  describe ":round" do
    context "with nullify set to false" do
      before do
        person_class = Class.new(Person) do
          sanitizes :income, round: 2
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "John", last_name: "anything", income: 12345.7777777) }

      it "rounds the number to the given decimal place" do
        expect(person.income).to eq(12345.78)
      end
    end
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

  describe "user-defined sanitizers" do
    context "with a user-defined sanitizer" do
      before do
        ssn_sanitizer_class = Class.new do
          def sanitize_each(record, attribute, value)
            value.gsub(/-/, '')
          end
        end
        stub_const('SsnSanitizer', ssn_sanitizer_class)

        person_class = Class.new(Person) do
          sanitizes :ssn, ssn: true
        end
        stub_const('Person', person_class)
      end
      let!(:person) { Person.create(first_name: "John", last_name: "anything", ssn: "-333-22-4444-") }

      it "runs the user-defined sanitizer" do
        expect(person.ssn).to eq("333224444")
      end
    end

    context "when there is no matching user-defined sanitizer" do
      it "runs the user-defined sanitizer" do
        expect {
          person_class = Class.new(Person) do
            sanitizes :ssn, ssn: true
          end
          stub_const('Person', person_class)
        }.to raise_error(ArgumentError, "Unknown sanitizer: :ssn")
      end
    end
  end

  describe "custom standalone model validator" do
    before do
      person_sanitizer_class = Class.new do
        def sanitize(record)
          record.first_name = "Harry"
          record.last_name = "Potter"
        end
      end
      stub_const('PersonSanitizer', person_sanitizer_class)

      person_class = Class.new(Person) do
        sanitizes_with PersonSanitizer
      end
      stub_const('Person', person_class)
    end
    let!(:person) { Person.create(first_name: "John", last_name: "anything") }

    it "runs the user-defined sanitizer" do
      expect(person.first_name).to eq("Harry")
      expect(person.last_name).to eq("Potter")
    end
  end

  context "with all the different possible sanitizers" do
    before do
      ssn_sanitizer_class = Class.new do
        def sanitize_each(record, attribute, value)
          value.gsub(/-/, '')
        end
      end
      stub_const('SsnSanitizer', ssn_sanitizer_class)

      person_sanitizer_class = Class.new do
        def sanitize(record)
          record.first_name = record.first_name[0,3] + "Harry"
        end
      end
      stub_const('PersonSanitizer', person_sanitizer_class)

      person_class = Class.new(Person) do
        sanitizes :first_name, case: :downcase
        sanitizes :last_name, case: :upcase, truncate: 6
        sanitizes :zip_code, remove: "-"
        sanitizes :ssn, ssn: true
        sanitizes_with PersonSanitizer

        before_sanitization :prepend
        after_sanitization :append

        def prepend
          self.first_name = "PRE" + self.first_name
        end
        def append
          self.first_name += "POST"
        end
      end
      stub_const('Person', person_class)
    end
    let!(:person) do
      Person.create(
        first_name: "John",
        last_name: "Jingleheimer",
        zip_code: "55555-4444-",
        ssn: "-333-22-4444-"
      )
    end

    it "runs everything, running standard sanitizers first, and model sanitizer next" do
      expect(person.first_name).to eq("preHarryPOST")
      expect(person.last_name).to eq("JINGLE")
      expect(person.zip_code).to eq("555554444")
      expect(person.ssn).to eq("333224444")
    end
  end
end
