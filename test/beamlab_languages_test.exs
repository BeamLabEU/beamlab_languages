defmodule BeamlabLanguagesTest do
  use ExUnit.Case, async: true
  doctest BeamlabLanguages

  describe "get/1" do
    test "returns a Language struct for known code" do
      assert %BeamlabLanguages.Language{code: "fr", name: "French"} =
               BeamlabLanguages.get("fr")
    end

    test "returns nil for unknown" do
      assert BeamlabLanguages.get("xx") == nil
    end

    test "collapses BCP 47 input" do
      assert BeamlabLanguages.get("en-US").code == "en"
      assert BeamlabLanguages.get("zh-Hans-CN").code == "zh"
    end

    test "is case-insensitive and trims" do
      assert BeamlabLanguages.get("FR").code == "fr"
      assert BeamlabLanguages.get(" fr ").code == "fr"
    end

    test "returns nil for nil / non-string input" do
      assert BeamlabLanguages.get(nil) == nil
      assert BeamlabLanguages.get(42) == nil
    end
  end

  describe "list/0 and list_codes/0" do
    test "list/0 is sorted by code" do
      codes = BeamlabLanguages.list() |> Enum.map(& &1.code)
      assert codes == Enum.sort(codes)
    end

    test "list_codes/0 is sorted" do
      codes = BeamlabLanguages.list_codes()
      assert codes == Enum.sort(codes)
    end

    test "covers at least 50 languages" do
      assert length(BeamlabLanguages.list()) >= 50
    end
  end

  describe "has_gender?/1" do
    test "returns expected values" do
      assert BeamlabLanguages.has_gender?("fr")
      assert BeamlabLanguages.has_gender?("de")
      refute BeamlabLanguages.has_gender?("en")
      refute BeamlabLanguages.has_gender?("ja")
    end

    test "returns false for unknown / nil / non-string" do
      refute BeamlabLanguages.has_gender?("xx")
      refute BeamlabLanguages.has_gender?(nil)
      refute BeamlabLanguages.has_gender?(42)
    end

    test "normalizes BCP 47 input" do
      assert BeamlabLanguages.has_gender?("fr-CA")
      refute BeamlabLanguages.has_gender?("en-US")
    end
  end

  describe "genders/1" do
    test "returns expected lists" do
      assert BeamlabLanguages.genders("fr") == ["m", "f"]
      assert BeamlabLanguages.genders("de") == ["m", "f", "n"]
      assert BeamlabLanguages.genders("en") == []
    end

    test "returns [] for unknown / nil" do
      assert BeamlabLanguages.genders("xx") == []
      assert BeamlabLanguages.genders(nil) == []
    end
  end

  describe "direction/1" do
    test "returns :rtl for RTL scripts" do
      assert BeamlabLanguages.direction("ar") == :rtl
      assert BeamlabLanguages.direction("he") == :rtl
      assert BeamlabLanguages.direction("fa") == :rtl
      assert BeamlabLanguages.direction("ur") == :rtl
    end

    test "returns :ltr for LTR languages and unknown codes" do
      assert BeamlabLanguages.direction("en") == :ltr
      assert BeamlabLanguages.direction("fr") == :ltr
      assert BeamlabLanguages.direction("xx") == :ltr
      assert BeamlabLanguages.direction(nil) == :ltr
    end
  end

  describe "name/1 and native_name/1" do
    test "returns canonical English names" do
      assert BeamlabLanguages.name("fr") == "French"
      assert BeamlabLanguages.name("ja") == "Japanese"
      assert BeamlabLanguages.name("ar") == "Arabic"
    end

    test "returns endonyms" do
      assert BeamlabLanguages.native_name("fr") == "Français"
      assert BeamlabLanguages.native_name("ja") == "日本語"
      assert BeamlabLanguages.native_name("de") == "Deutsch"
    end

    test "returns nil for unknown" do
      assert BeamlabLanguages.name("xx") == nil
      assert BeamlabLanguages.native_name("xx") == nil
    end
  end

  describe "normalize/1" do
    test "strips dialect and lowercases" do
      assert BeamlabLanguages.normalize("en-US") == "en"
      assert BeamlabLanguages.normalize("FR") == "fr"
      assert BeamlabLanguages.normalize("zh-Hans-CN") == "zh"
    end

    test "accepts underscore separator" do
      assert BeamlabLanguages.normalize("en_US") == "en"
    end

    test "trims whitespace" do
      assert BeamlabLanguages.normalize("  fr  ") == "fr"
    end

    test "returns nil for empty / non-alpha / nil" do
      assert BeamlabLanguages.normalize("") == nil
      assert BeamlabLanguages.normalize(nil) == nil
      assert BeamlabLanguages.normalize("123") == nil
      assert BeamlabLanguages.normalize("a") == nil
      assert BeamlabLanguages.normalize("eng") == nil
    end

    test "does not validate that the base is a known language" do
      # normalize/1 only extracts a base — it does NOT check membership.
      # That's get/1 / known?/1's job.
      assert BeamlabLanguages.normalize("xx") == "xx"
    end

    test "maps nb / nn to no" do
      assert BeamlabLanguages.normalize("nb") == "no"
      assert BeamlabLanguages.normalize("nn") == "no"
      assert BeamlabLanguages.normalize("nb-NO") == "no"
      assert BeamlabLanguages.normalize("NN_no") == "no"
    end
  end

  describe "Norwegian aliases" do
    test "nb / nn resolve through the rest of the API" do
      assert BeamlabLanguages.get("nb-NO").code == "no"
      assert BeamlabLanguages.name("nn") == "Norwegian"
      assert BeamlabLanguages.known?("nb")
    end
  end

  describe "known?/1" do
    test "returns true for known codes" do
      assert BeamlabLanguages.known?("fr")
      assert BeamlabLanguages.known?("en-US")
    end

    test "returns false for unknown / nil" do
      refute BeamlabLanguages.known?("xx")
      refute BeamlabLanguages.known?(nil)
      refute BeamlabLanguages.known?("")
    end
  end

  describe "data integrity" do
    test "every entry has every required field, well-formed" do
      for lang <- BeamlabLanguages.list() do
        assert is_binary(lang.code) and byte_size(lang.code) == 2,
               "bad code: #{inspect(lang.code)}"

        assert is_binary(lang.name) and lang.name != ""
        assert is_binary(lang.native_name) and lang.native_name != ""
        assert lang.direction in [:ltr, :rtl]
        assert is_boolean(lang.has_gender)
        assert is_list(lang.genders)
        if lang.has_gender, do: assert(lang.genders != [])
        if not lang.has_gender, do: assert(lang.genders == [])
      end
    end

    test "codes are unique" do
      codes = BeamlabLanguages.list_codes()
      assert length(codes) == length(Enum.uniq(codes))
    end
  end
end
