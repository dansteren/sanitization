Temping.create :person do
  with_columns do |t|
    t.string :first_name
    t.string :last_name, null: false
    # Need some sort of DB contraint or
    # ActiveRecord::Base.connection.data_source_exists? is false for some reason,
    t.boolean :active
    #
    # t.string :company
    # t.string :address
    # t.string :city, null: false
    # t.string :title
    # t.string :email, null: false
    # t.text   :description
    # t.text   :education
    # t.string :do_not_collapse, null: false
    # t.date   :dob
    # t.integer :age
    # t.string '1337'
  end
end

# class Person
#   sanitizes :first_name, strip: true, truncate: 6
#     # case: :up|:down|:camel|:snake|:title|:pascal,
#     # gsub: { pattern: /[aeiou]/, replacement: '*' },
#     # nullify: true, # converts empty/blank strings to null
#     # remove: /[aeiou]/,
#     # round: 2, # Rounds a float to the given number of decimal places
#     # squish: true, # Removes surrounding whitespace and internal consecutive whitespace characters
#     # ssn: true, # Custom sanitizer from EachSanitizer
#     # strip: true, # Removes surrounding whitespace
#     # truncate: 50, # truncates values to a given length. If we can't detect what the DB accepts
#     # truncate: true # truncates values that are too long. Would need to know the DB limits, or we should use the next line


#   # `sanitization` is an alias of `sanitizes`
#   sanitize :last_name, squish: true
# end

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
