@Component
export struct AmountInput {
  @Link amountText: string;

  build() {
    Column({ space: 8 }) {
      Text('金额')
        .fontSize(13)
        .fontColor('#7A8074')
        .width('100%')

      TextInput({ text: this.amountText, placeholder: '0.00' })
        .type(InputType.Number)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#171A15')
        .placeholderColor('#BFC4B8')
        .height(64)
        .backgroundColor('#F1F3ED')
        .borderRadius(8)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.amountText = this.normalize(value);
        })
    }
  }

  private normalize(value: string): string {
    const cleaned = value.replace(/[^\d.]/g, '');
    const parts = cleaned.split('.');
    if (parts.length <= 1) {
      return cleaned;
    }
    return `${parts[0]}.${parts.slice(1).join('').substring(0, 2)}`;
  }
}

