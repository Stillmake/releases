cask "__SLUG__" do
  version "__VERSION__,__BUILD__"
  sha256 "__SHA256__"

  url "https://github.com/Stillmake/releases/releases/download/__SLUG__-#{version.csv.first}-#{version.csv.second}/__APP__.dmg"
  name "__APP__"
  desc "__DESC__"
  homepage "__HOMEPAGE__"

  livecheck do
    url "https://raw.githubusercontent.com/Stillmake/releases/main/__SLUG__/version.json"
    strategy :json do |json|
      json.map { |release| "#{release["version"]},#{release["build"]}" }
    end
  end

  auto_updates true
  depends_on macos: :__MACOS__

  app "__APP__.app"

  zap trash: [
    "~/Library/Application Support/__BUNDLE_ID__",
    "~/Library/Caches/__BUNDLE_ID__",
    "~/Library/HTTPStorages/__BUNDLE_ID__",
    "~/Library/Preferences/__BUNDLE_ID__.plist",
    "~/Library/Saved Application State/__BUNDLE_ID__.savedState",
  ]
end
