defmodule Agregat.DateParser do
  # Try to parse the date in parameter and return an Ecto.DateTime.
  # If the date cannot be parsed, return nil.
  def parse(nil) do nil end
  def parse(date) do
    case Timex.parse(date, guess_dateformat(date)) do
      {:ok, parsed_date} -> parsed_date
      {:error, _} -> nil
    end
  end

  # Guess the Timex date format for the date in parameter.
  defp guess_dateformat(date) do
    cond do
      date =~ ~r/^\w{3},\s\d{1,2}\s\w{3}\s\d{1,2}\s\d{1,2}:\d{2}:\d{2}\sZ$/i -> "{RFC822z}"
      date =~ ~r/^\w{3},\s\d{1,2}\s\w{3}\s\d{1,2}\s\d{1,2}:\d{2}:\d{2}\s\w{1,2}$/i -> "{RFC822}"
      date =~ ~r/^\w{3},\s\d{1,2}\s\w{3}\s\d{4}\s\d{1,2}:\d{2}:\d{2}\sZ$/i -> "{RFC1123z}"
      date =~ ~r/^\w{3},\s\d{1,2}\s\w{3}\s\d{4}\s\d{1,2}:\d{2}:\d{2}\s\w{3}$/i -> "{WDshort}, {0D} {Mshort} {YYYY} {h24}:{m}:{s} {Zname}"
      date =~ ~r/^\w{3},\s\d{1,2}\s\w{3}\s\d{4}\s\d{1,2}:\d{2}:\d{2}\s[+-]\d{4}$/i -> "{RFC1123}"
      date =~ ~r/^\d{4}-\d{1,2}-\d{1,2}T\d{1,2}:\d{2}:\d{2}Z$/i -> "{RFC3339z}"
      date =~ ~r/^\d{4}-\d{1,2}-\d{1,2}T\d{1,2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/i -> "{RFC3339}"
      date =~ ~r/^\w{3}\s\w{3}\s\d{1,2}\s\d{1,2}:\d{2}:\d{2}\s\d{4}$/i -> "{ANSIC}"
      date =~ ~r/^\w{3}\s\w{3}\s\d{1,2}\s\d{1,2}:\d{2}:\d{2}\s\w{3}\s\d{4}$/i -> "{UNIX}"

      date =~ ~r/^\d{1,2}\s[a-z]{4,}\s\d{4}\s\d{1,2}:\d{2}:\d{2}$/i -> "{0D} {Mfull} {YYYY} {h24}:{m}:{s}"
      date =~ ~r/^\d{1,2}\s[a-z]{3}\s\d{4}\s\d{1,2}:\d{2}:\d{2}$/i -> "{0D} {Mshort} {YYYY} {h24}:{m}:{s}"
      date =~ ~r/^\d{4}\/\d{1,2}\/\d{1,2}\s\d{1,2}:\d{2}:\d{2}$/i -> "{YYYY}/{0M}/{0D} {h24}:{m}:{s}"
      date =~ ~r/^\d{1,2}\/\d{1,2}\/\d{4}\s\d{1,2}:\d{2}:\d{2}$/i -> "{0M}/{0D}/{YYYY} {h24}:{m}:{s}"
      date =~ ~r/^\d{4}-\d{1,2}-\d{1,2}\s\d{1,2}:\d{2}:\d{2}$/i -> "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
      date =~ ~r/^\d{1,2}-\d{1,2}-\d{4}\s\d{1,2}:\d{2}:\d{2}$/i -> "{0D}-{0M}-{YYYY} {h24}:{m}:{s}"
      date =~ ~r/^\d{8}\s\d{6}$/i -> "{YYYY}{0M}{0D} {h24}{m}{s}"
      date =~ ~r/^\d{14}$/i -> "{YYYY}{0M}{0D}{h24}{m}{s}"

      date =~ ~r/^\d{1,2}\s[a-z]{4,}\s\d{4}\s\d{1,2}:\d{2}$/i -> "{0D} {Mfull} {YYYY} {h24}:{m}"
      date =~ ~r/^\d{1,2}\s[a-z]{3}\s\d{4}\s\d{1,2}:\d{2}$/i -> "{0D} {Mshort} {YYYY} {h24}:{m}"
      date =~ ~r/^\d{4}\/\d{1,2}\/\d{1,2}\s\d{1,2}:\d{2}$/i -> "{YYYY}/{0M}/{0D} {h24}:{m}"
      date =~ ~r/^\d{1,2}\/\d{1,2}\/\d{4}\s\d{1,2}:\d{2}$/i -> "{0M}/{0D}/{YYYY} {h24}:{m}"
      date =~ ~r/^\d{4}-\d{1,2}-\d{1,2}\s\d{1,2}:\d{2}$/i -> "{YYYY}-{0M}-{0D} {h24}:{m}"
      date =~ ~r/^\d{1,2}-\d{1,2}-\d{4}\s\d{1,2}:\d{2}$/i -> "{0D}-{0M}-{YYYY} {h24}:{m}"
      date =~ ~r/^\d{8}\s\d{4}$/i -> "{YYYY}{0M}{0D} {h24}{m}"
      date =~ ~r/^\d{12}$/i -> "{YYYY}{0M}{0D}{h24}{m}"

      date =~ ~r/^\d{1,2}\s[a-z]{4,}\s\d{4}$/i -> "{0D} {Mfull} {YYYY}"
      date =~ ~r/^\d{1,2}\s[a-z]{3}\s\d{4}$/i -> "{0D} {Mshort} {YYYY}"
      date =~ ~r/^\d{4}\/\d{1,2}\/\d{1,2}$/i -> "{YYYY}/{0M}/{0D}"
      date =~ ~r/^\d{1,2}\/\d{1,2}\/\d{4}$/i -> "{0M}/{0D}/{YYYY}"
      date =~ ~r/^\d{4}-\d{1,2}-\d{1,2}$/i -> "{YYYY}-{0M}-{0D}"
      date =~ ~r/^\d{1,2}-\d{1,2}-\d{4}$/i -> "{0D}-{0M}-{YYYY}"
      date =~ ~r/^\d{8}$/i -> "{YYYY}{0M}{0D}"

      true -> ""
    end
  end
end
