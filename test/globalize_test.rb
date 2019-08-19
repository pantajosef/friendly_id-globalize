# encoding: utf-8
require 'test_helper'

class GlobalizeTest < MiniTest::Test
  def setup
    I18n.locale = :en
  end

  test 'should have a value for friendly_id after creation' do
    transaction do
      article = ::I18n.with_locale(:de) { Article.create!(:title => 'Der Herbst des Einsamen') }
      refute_nil article.friendly_id
    end
  end

  test "should find slug in current locale if locale is set, otherwise in default locale" do
    transaction do
      I18n.default_locale = :en
      article_en = I18n.with_locale(:en) { Article.create!(:title => 'a title') }
      article_de = I18n.with_locale(:de) { Article.create!(:title => 'titel') }

      I18n.with_locale(:de) do
        assert_equal Article.friendly.find("titel"), article_de
        assert_equal Article.friendly.find("a-title"), article_en
      end
    end
  end

  test "should set friendly id for locale" do
    transaction do
      article = Article.create!(:title => "War and Peace")
      article.set_friendly_id("Guerra y paz", :es)
      article.set_friendly_id("Guerra e pace", :it)
      article.save!
      found_article = Article.friendly.find('war-and-peace')
      I18n.with_locale(:es) { assert_equal "guerra-y-paz", found_article.friendly_id }
      I18n.with_locale(:en) { assert_equal "war-and-peace", found_article.friendly_id }
      I18n.with_locale(:it) { assert_equal "guerra-e-pace", found_article.friendly_id }
    end
  end

  test "should set all friendly ids for each nested translation" do
    transaction do
      article = Article.create!(translations_attributes: {
        xx: { title: 'Guerra e pace', locale: 'it' },
        yy: { title: 'Guerre et paix', locale: 'fr' },
        zz: { title: 'Guerra y paz', locale: 'es' }
      })
      I18n.with_locale(:it) { assert_equal "guerra-e-pace", article.friendly_id }
      I18n.with_locale(:fr) { assert_equal "guerre-et-paix", article.friendly_id }
      I18n.with_locale(:es) { assert_equal "guerra-y-paz", article.friendly_id }
    end
  end

  # https://github.com/svenfuchs/globalize3/blob/master/test/globalize3/dynamic_finders_test.rb#L101
  # see: https://github.com/svenfuchs/globalize3/issues/100
  test "record returned by friendly_id should have all translations" do
    transaction do
      I18n.with_locale(:en) do
        article = Article.create!(:title => 'a title')
        Globalize.with_locale(:de) {article.update_attribute(:title, 'ein titel')}
        article_by_friendly_id = Article.friendly.find("a-title")
        article.translations.each do |translation|
          assert_includes article_by_friendly_id.translations, translation
        end
      end
    end
  end
end
