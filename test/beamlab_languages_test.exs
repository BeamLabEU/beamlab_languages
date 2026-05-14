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

  describe "has_verb_conjugation?/1" do
    test "returns true for languages with a curated paradigm" do
      assert BeamlabLanguages.has_verb_conjugation?("fr")
    end

    test "returns false for analytic / uncurated languages" do
      refute BeamlabLanguages.has_verb_conjugation?("zh")
      refute BeamlabLanguages.has_verb_conjugation?("en")
      refute BeamlabLanguages.has_verb_conjugation?("ja")
    end

    test "returns false for unknown / nil / non-string" do
      refute BeamlabLanguages.has_verb_conjugation?("xx")
      refute BeamlabLanguages.has_verb_conjugation?(nil)
      refute BeamlabLanguages.has_verb_conjugation?(42)
    end

    test "normalizes BCP 47 input" do
      assert BeamlabLanguages.has_verb_conjugation?("fr-CA")
      assert BeamlabLanguages.has_verb_conjugation?("FR")
      assert BeamlabLanguages.has_verb_conjugation?(" fr ")
    end
  end

  describe "verb_groups/1" do
    test "returns the French group system" do
      groups = BeamlabLanguages.verb_groups("fr")
      assert length(groups) == 3
      assert Enum.map(groups, & &1.key) == ["1", "2", "3"]
      assert hd(groups).label_native =~ "groupe"
      assert hd(groups).label_en =~ "group"
    end

    test "returns nil for languages without a curated paradigm" do
      assert BeamlabLanguages.verb_groups("zh") == nil
      assert BeamlabLanguages.verb_groups("en") == nil
    end

    test "returns nil for unknown / nil" do
      assert BeamlabLanguages.verb_groups("xx") == nil
      assert BeamlabLanguages.verb_groups(nil) == nil
    end

    test "normalizes BCP 47 input" do
      assert BeamlabLanguages.verb_groups("fr-CA") == BeamlabLanguages.verb_groups("fr")
    end
  end

  describe "persons/1" do
    test "returns the French six-person list" do
      persons = BeamlabLanguages.persons("fr")
      assert length(persons) == 6
      assert Enum.map(persons, & &1.key) == ["1sg", "2sg", "3sg", "1pl", "2pl", "3pl"]
      assert hd(persons) == %{key: "1sg", label_native: "je", label_en: "I"}
    end

    test "every entry has both native and English labels" do
      for p <- BeamlabLanguages.persons("fr") do
        assert is_binary(p.label_native) and p.label_native != ""
        assert is_binary(p.label_en) and p.label_en != ""
      end
    end

    test "returns nil for uncurated / unknown" do
      assert BeamlabLanguages.persons("zh") == nil
      assert BeamlabLanguages.persons("xx") == nil
      assert BeamlabLanguages.persons(nil) == nil
    end
  end

  describe "conjugation_paradigm/1" do
    test "returns the French paradigm shape" do
      paradigm = BeamlabLanguages.conjugation_paradigm("fr")
      assert is_map(paradigm)
      assert is_list(paradigm.modes)

      assert Enum.map(paradigm.modes, & &1.key) ==
               ["indicatif", "subjonctif", "conditionnel", "imperatif"]
    end

    test "indicatif has 8 tenses in teaching order" do
      [indicatif | _] = BeamlabLanguages.conjugation_paradigm("fr").modes
      assert indicatif.label_native == "Indicatif"
      assert indicatif.label_en == "Indicative"

      assert Enum.map(indicatif.tenses, & &1.key) == [
               "present",
               "passe_compose",
               "imparfait",
               "plus_que_parfait",
               "passe_simple",
               "passe_anterieur",
               "futur_simple",
               "futur_anterieur"
             ]
    end

    test "every mode and tense has both native and English labels" do
      for mode <- BeamlabLanguages.conjugation_paradigm("fr").modes do
        assert is_binary(mode.label_native) and mode.label_native != ""
        assert is_binary(mode.label_en) and mode.label_en != ""

        for tense <- mode.tenses do
          assert is_binary(tense.key) and tense.key != ""
          assert is_binary(tense.label_native) and tense.label_native != ""
          assert is_binary(tense.label_en) and tense.label_en != ""
        end
      end
    end

    test "returns nil for uncurated / unknown" do
      assert BeamlabLanguages.conjugation_paradigm("zh") == nil
      assert BeamlabLanguages.conjugation_paradigm("xx") == nil
      assert BeamlabLanguages.conjugation_paradigm(nil) == nil
    end

    test "has_verb_conjugation? agrees with conjugation_paradigm" do
      for code <- BeamlabLanguages.list_codes() do
        assert BeamlabLanguages.has_verb_conjugation?(code) ==
                 (BeamlabLanguages.conjugation_paradigm(code) != nil)
      end
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

  describe "level_systems/0" do
    test "returns sorted list of known systems" do
      assert BeamlabLanguages.level_systems() == ["cefr", "hsk", "jlpt"]
    end
  end

  describe "levels/1" do
    test "returns CEFR levels in pedagogical order" do
      assert BeamlabLanguages.levels("cefr") == ["A1", "A2", "B1", "B2", "C1", "C2"]
    end

    test "returns JLPT levels in pedagogical order" do
      assert BeamlabLanguages.levels("jlpt") == ["N5", "N4", "N3", "N2", "N1"]
    end

    test "returns HSK levels in pedagogical order" do
      assert BeamlabLanguages.levels("hsk") == ["HSK1", "HSK2", "HSK3", "HSK4", "HSK5", "HSK6"]
    end

    test "returns [] for unknown system" do
      assert BeamlabLanguages.levels("unknown") == []
    end
  end

  describe "level_system_label/1" do
    test "returns labels for known systems" do
      assert BeamlabLanguages.level_system_label("cefr") == "CEFR"
      assert BeamlabLanguages.level_system_label("jlpt") == "JLPT"
      assert BeamlabLanguages.level_system_label("hsk") == "HSK"
    end

    test "returns nil for unknown system" do
      assert BeamlabLanguages.level_system_label("unknown") == nil
    end
  end

  describe "level_info/2" do
    test "returns metadata for known system and level" do
      assert BeamlabLanguages.level_info("cefr", "A1") == %{
               key: "A1",
               label: "A1",
               description: "Beginner"
             }

      assert BeamlabLanguages.level_info("jlpt", "N1") == %{
               key: "N1",
               label: "N1",
               description: "Advanced"
             }

      assert BeamlabLanguages.level_info("hsk", "HSK3") == %{
               key: "HSK3",
               label: "HSK 3",
               description: "Intermediate"
             }
    end

    test "returns nil for unknown system" do
      assert BeamlabLanguages.level_info("unknown", "A1") == nil
    end

    test "returns nil for unknown level" do
      assert BeamlabLanguages.level_info("cefr", "Z9") == nil
    end
  end
end
