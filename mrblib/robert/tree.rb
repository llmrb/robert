# frozen_string_literal: true

module Robert
  ##
  # The {Tree} module builds the UI tree when the
  # application boots.
  #
  # Layout:
  #
  #   VBox root
  #   ├── HBox body (flex)
  #   │   ├── Fill
  #   │   ├── Chat
  #   │   └── Fill
  #   ├── StatusBar (height: 1)
  #   └── Input (height: 1)
  module Tree
    extend self

    ##
    # @return [LLM::Object]
    #  Returns a UI tree
    def build(llm)
      ui = LLM::Object.from({})
      ui.root = TUI::VBox.new
      ui.body = TUI::HBox.new
      ui.left_fill = fill(width: 0.2)
      ui.center = Widgets::Pane.new(width: 0.6)
      ui.chat = chat
      ui.banner = banner
      ui.right_fill = fill(width: 0.2)
      ui.status = status_bar(llm)
      ui.input = TUI::Input.new(height: 3, fg: :default, bg: :default, valign: :middle)
      ui.center.show(ui.banner)
      ui.body.add(ui.left_fill)
      ui.body.add(ui.center)
      ui.body.add(ui.right_fill)
      ui.root.add(ui.body)
      ui.root.add(ui.status)
      ui.root.add(ui.input)
      ui
    end

    private

    def fill(width:)
      TUI::Fill.new(width:, fg: :default, bg: :default)
    end

    def chat
      TUI::Chat.new(
        roles: true,
        assistant_fg: :red,
        labels: {user: "You", assistant: "Robert"}
      )
    end

    def banner
      Widgets::Splash.new(
        "FreeBSD Tip:",
        Robert.boot_message,
        fg: :white,
        bg: :default
      )
    end

    ##
    # @api private
    def status_bar(llm)
      TUI::StatusBar.new(
        llm ? "Idle" : "No LLM configured",
        right: llm.key? ? "" : "set DEEPSEEK_SECRET",
        fg: :white,
        bg: :default
      )
    end
  end
end
