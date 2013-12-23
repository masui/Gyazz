class KeywordTest < MiniTest::Unit::TestCase
  def test_1
    s = "[[abc]] [[def]] などはキーワード"
    keywords = s.keywords
    assert_equal keywords.length, 2
    assert keywords.member?('abc')
    assert keywords.member?('def')
  end

  def test_2
    s = "[[http://example.org/]] [[@masui]] などはキーワードにならない"
    keywords = s.keywords
    assert_equal keywords.length, 0
  end

  def test_3
    s = "[[E139.25.46.31N35.22.19.50Z17]]もキーワードにならない"
    keywords = s.keywords
    assert_equal keywords.length, 0
  end

  #def test_4
  #  s = "[[abc.iconx4]] [[def.icon*4]] [[増井.icon×3]] などはキーワード?"
  #  keywords = s.keywords
  #  assert_equal keywords.length, 3
  #  assert keywords.member?('abc')
  #  assert keywords.member?('def')
  #  assert keywords.member?('増井')
  #end

end