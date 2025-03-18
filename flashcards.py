# Android Flashcard Application using Kivy
import pandas as pd
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.spinner import Spinner
from kivy.uix.togglebutton import ToggleButton
from kivy.uix.popup import Popup

class FlashcardApp(App):
    def build(self):
        self.df = pd.read_excel("flashcards.xlsx")
        self.filtered_df = pd.DataFrame()
        self.index = 0

        layout = BoxLayout(orientation='vertical', padding=10, spacing=10)

        self.chapter_spinner = Spinner(text='All', values=[str(ch) for ch in self.df['Chapter'].unique()] + ["All"])
        self.type_spinner = Spinner(text='All', values=["All", "Derivation", "Concept"])
        self.diff_spinner = Spinner(text='All', values=["All", "Easy", "Intermediate", "Advanced"])
        self.random_toggle = ToggleButton(text="Randomize: No", state='normal')
        self.random_toggle.bind(on_press=self.toggle_random)

        start_btn = Button(text="Start Flashcards")
        start_btn.bind(on_press=self.start_flashcards)

        layout.add_widget(self.chapter_spinner)
        layout.add_widget(self.type_spinner)
        layout.add_widget(self.diff_spinner)
        layout.add_widget(self.random_toggle)
        layout.add_widget(start_btn)

        return layout

    def toggle_random(self, instance):
        instance.text = "Randomize: Yes" if instance.state == 'down' else "Randomize: No"

    def start_flashcards(self, instance):
        df = self.df
        if self.chapter_spinner.text != "All":
            df = df[df['Chapter'].astype(str) == self.chapter_spinner.text]
        if self.type_spinner.text != "All":
            df = df[df['Type'] == self.type_spinner.text]
        if self.diff_spinner.text != "All":
            df = df[df['Difficulty'] == self.diff_spinner.text]
        if self.random_toggle.state == 'down':
            df = df.sample(frac=1).reset_index(drop=True)

        if df.empty:
            popup = Popup(title='No Match', content=Label(text='No flashcards match your criteria.'), size_hint=(0.8, 0.3))
            popup.open()
            return

        self.filtered_df = df.reset_index(drop=True)
        self.index = 0
        self.show_flashcard()

    def show_flashcard(self):
        flashcard_layout = BoxLayout(orientation='vertical', padding=10, spacing=10)

        question = Label(text=self.filtered_df.loc[self.index, 'Question'], halign="center")
        answer_btn = Button(text="Show Answer")
        answer_btn.bind(on_press=self.show_answer)

        next_btn = Button(text="Next")
        prev_btn = Button(text="Previous")
        next_btn.bind(on_press=self.next_card)
        prev_btn.bind(on_press=self.prev_card)

        flashcard_layout.add_widget(question)
        flashcard_layout.add_widget(answer_btn)
        flashcard_layout.add_widget(next_btn)
        flashcard_layout.add_widget(prev_btn)

        self.popup = Popup(title=f"Flashcard {self.index + 1}/{len(self.filtered_df)}", content=flashcard_layout, size_hint=(0.9, 0.9))
        self.popup.open()

    def show_answer(self, instance):
        answer_popup = Popup(title="Answer", content=Label(text=self.filtered_df.loc[self.index, 'Answer']), size_hint=(0.8, 0.5))
        answer_popup.open()

    def next_card(self, instance):
        answer_popup = Popup(title="Answer", content=Label(text=self.filtered_df.loc[self.index, 'Answer']), size_hint=(0.8, 0.5))
        answer_popup.open()
        self.index = (self.index + 1) % len(self.filtered_df)
        self.popup.dismiss()
        self.show_flashcard()

    def prev_card(self, instance):
        self.index = (self.index - 1) % len(self.filtered_df)
        self.popup.dismiss()
        self.show_flashcard()

if __name__ == '__main__':
    FlashcardApp().run()

