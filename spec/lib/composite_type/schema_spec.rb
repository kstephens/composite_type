require 'spec_helper'
require 'composite_type/schema'

class CompositeType::Schema
  Schema = self
  describe self do
    before { $break = 0 }
    subject { Schema }

    context ".[]" do
      it "constructs Literal values" do
        t = subject[nil]
        expect(t === nil)    .to be_truthy
        expect(t === true)   .to be_falsey
        expect(t === false)  .to be_falsey
        expect(t === 1)      .to be_falsey
        expect(t === Object) .to be_falsey
        expect(t === t)      .to be_falsey
      end
      it "leave Modules alone" do
        t = subject[Object]
        expect(t.match) .to eq Object
      end
      it "constructs EnumerableType" do
        t = subject[[1, Symbol, 3]]
        expect(t === [1, :a, 3])
          .to be_truthy
        expect(t === true)
          .to be_falsey
      end
      it "constructs HashType" do
        t = subject[{Symbol => 1}]
        expect(t === nil)
          .to be_falsey
        expect(t === { })
          .to be_falsey
        expect(t === { a: 1 })
          .to be_truthy
        expect(t === { a: 2 })
          .to be_falsey

        t = subject[{:a => Numeric, Optional[:b] => String, Ellipsis => Object}]
        expect(t === nil)
          .to be_falsey
        expect(t === {})
          .to be_falsey
        expect(t === {a: 1, b: "s"})
          .to be_truthy
        expect(t === {a: 1, b: "s", c: 3})
          .to be_truthy
        expect(t === {a: 1, b: 2, c: 3})
          .to be_truthy
        expect(t === {a: 1, c: 3})
          .to be_truthy
      end
    end

    describe Many do
      context "in Enumerable" do
        context "[Module]" do
          it "matches zero or more" do
            t = subject[[Many[Symbol], Many[Integer]]]
            expect(t === [ ])
              .to be_truthy
            expect(t === [ :a, :b, :c ])
              .to be_truthy
            expect(t === [ 1, 2, 3 ])
              .to be_truthy
            expect(t === [ :a, :b, :c, 1, 2, 3 ])
              .to be_truthy
            expect(t === [ 1, 2, 3, :a, :b, :c ])
              .to be_falsey
            expect(t === [ :a, "sd", 1 ])
              .to be_falsey
          end
        end
        context "[Module,1,2]" do
          it "matches zero or more" do
            t = subject[[Many[Symbol, 1, 2], Many[Integer, 1, 2]]]
            expect(t === [ ])
              .to be_falsey
            expect(t === [ :a, 1 ])
              .to be_truthy
            expect(t === [ :a, :b, 1 ])
              .to be_truthy
            expect(t === [ :a, :b, 1, 2 ])
              .to be_truthy
            expect(t === [ :a, :b, :c, 1, 2 ])
              .to be_falsey
            expect(t === [ :a, :b, 1, 2, "asdf"])
              .to be_falsey
            expect(t === [ :a, :b, :c, 1, 2, 3 ])
              .to be_falsey
            expect(t === [ 1, 2, 3, :a, :b, :c ])
              .to be_falsey
            expect(t === [ :a, "sd", 1 ])
              .to be_falsey
          end
        end
      end
      context "in Hash" do
        context "[Module]" do
          it "matches zero or more" do
            t = subject[{ Many[Symbol] => Integer }]
            expect(t === { })
              .to be_truthy
            expect(t === { a: 1 })
              .to be_truthy
            expect(t === { a: 1, b: 2 })
              .to be_truthy
            expect(t === { a: "str" })
              .to be_falsey
            expect(t === { a: 1, b: 2, "foo": :bar })
              .to be_falsey
          end
        end
        context "[Module,1,2]" do
          it "matches zero or more" do
            t = subject[{ Many[Symbol, 1, 2] => Integer }]
            expect(t === { })
              .to be_falsey
            expect(t === { a: 1 })
              .to be_truthy
            expect(t === { a: 1, b: 2 })
              .to be_truthy
            expect(t === { a: 1, b: 2, c: 3 })
              .to be_falsey
            expect(t === { a: "str" })
              .to be_falsey
            expect(t === { a: 1, b: 2, "foo": :bar })
              .to be_falsey
          end
        end
      end

    end

    describe Optional do
      it "matches" do
        expect( Optional[:a] === :a ) .to be_truthy
        expect( Optional[:b] === :a ) .to be_falsey
      end
    end

    describe EnumerableType do
      subject { EnumerableType[proto] }
      describe "#===" do
        EXAMPLES = [
          [ ],
          [ 1 ],
          [ 1, 2 ],
          [ 1, 2, Module ],
        ]
        EXAMPLES.each do | proto_ |
          context "#{proto_.inspect}" do
            let(:proto) { proto_.dup }
            EXAMPLES.each do | example_ |
              context "== #{example_.inspect}" do
                let(:example) { example_.dup }
                it "is true only for == Enumerables" do
                  if proto == example
                    expect( subject === example ) .to be_truthy
                  else
                    expect( subject === example ) .to be_falsey
                  end
                end
              end
            end
          end
        end

        context Optional do
          subject { EnumerableType[[1, Optional[2], 3]] }
          it "matches" do
            expect( subject === [ ] )
              .to be_falsey
            expect( subject === [ 1 ] )
              .to be_falsey
            expect( subject === [ 1, 2 ] )
              .to be_falsey
            expect( subject === [ 1, 2, 3 ] )
              .to be_truthy
            expect( subject === [ 1, 3 ] )
              .to be_truthy
          end
        end

        context "[Ellipsis]" do
          let(:proto) { [Ellipsis] }
          it "is true all Enumerables" do
            expect( subject === [] )  .to be_truthy
            expect( subject === [1] ) .to be_truthy
            expect( subject === [1,2] ) .to be_truthy
          end
        end
        context "[1, Ellipsis]" do
          let(:proto) { [1, Ellipsis] }
          it "is true for [1,..]" do
            expect( subject === [] )    .to be_falsey
            expect( subject === [1] )   .to be_truthy
            expect( subject === [1,2] ) .to be_truthy
            expect( subject === [2] )   .to be_falsey
          end
        end
      end
    end

    describe HashType do
      subject { HashType[proto] }
      describe "#===" do
        EXAMPLES = [
          { },
          { a: 1 },
          { a: 1, b: 2 },
          { b: 2, a: 1 },
          { a: 2, b: 2 },
          { a: 1, b: 3 },
          { a: 1, b: 2, c: 3 },
        ]
        EXAMPLES.each do | proto_ |
          context "#{proto_.inspect}" do
            let(:proto) { proto_.dup }
            EXAMPLES.each do | example_ |
              context "== #{example_.inspect}" do
                let(:example) { example_.dup }
                it "is true only for == Enumerables" do
                  if proto == example
                    expect( subject === example ) .to be_truthy
                  else
                    expect( subject === example ) .to be_falsey
                  end
                end
              end
            end
          end
        end
        context "{ a: Object }" do
          let(:proto) { { a: Object } }
          it "is true" do
            expect( subject === {} )
              .to be_falsey
            expect( subject === { a: 1 } )
              .to be_truthy
            expect( subject === { b: 1 } )
              .to be_falsey
            expect( subject === { a: 1, b: 2 } )
              .to be_falsey
          end
        end
        context "{ Symbol => Numeric }" do
          let(:proto) { { Symbol => Numeric } }
          it "matches" do
            expect( subject === {} )
              .to be_falsey
            expect( subject === { a: 1 } )
              .to be_truthy
            expect( subject === { a: :b } )
              .to be_falsey
            expect( subject === { a: 1, b: 2 } )
              .to be_falsey
          end
        end

        context Optional do
          it "matches" do
            h = HashType[Optional[:a] => Numeric]
            expect( h === { } )
              .to be_truthy
            expect( h === { a: 1 } )
              .to be_truthy
            expect( h === { a: "str"} )
              .to be_falsey
            expect( h === { a: 1, b: 2 } )
              .to be_falsey

            h = HashType[Optional[:a] => Numeric, b: 2]
            expect( h === { a: 1, b: 2 } )
              .to be_truthy
            expect( h === { b: 2 } )
              .to be_truthy
            expect( h === { a: 2, b: 3 } )
              .to be_falsey
            expect( h === { b: 3 } )
              .to be_falsey
            expect( h === { b: 2, c: 2 } )
              .to be_falsey
          end
        end

        [
          { Ellipsis => 1 },
        ].each do | proto_ |
          context "#{proto_.inspect}" do
            let(:proto) { proto_ }
            it "is true all Hashes" do
              expect( subject === {} )
                .to be_truthy
              expect( subject === {a: 1} )
                .to be_truthy
              expect( subject === {a: 1, b: 2} )
                .to be_truthy
            end
          end
        end
      end
    end
  end
end
