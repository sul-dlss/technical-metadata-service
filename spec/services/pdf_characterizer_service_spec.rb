# frozen_string_literal: true

require 'open3'

RSpec.describe PdfCharacterizerService do
  let(:service) { described_class.new }

  let(:text_output) { '   ' }

  let(:text_status) { instance_double(Process::Status, success?: true) }

  before do
    allow(Open3).to receive(:capture2e).and_return([output, status], [text_output, text_status])
  end

  describe '#version' do
    let(:version) { service.version }

    context 'when poppler returns version' do
      let(:output) do
        <<~OUTPUT
          pdfinfo version 0.85.0
          Copyright 2005-2020 The Poppler Developers - http://poppler.freedesktop.org
          Copyright 1996-2011 Glyph & Cog, LLC
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns version' do
        expect(version).to eq('0.85.0')
        expect(Open3).to have_received(:capture2e).with('pdfinfo -v')
      end
    end

    context 'when poppler fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises' do
        expect { version }.to raise_error(PdfCharacterizerService::Error)
      end
    end

    context 'when popper produces unexpected results' do
      let(:status) { instance_double(Process::Status, success?: true) }
      let(:output) { 'What??' }

      it 'raises' do
        expect { version }.to raise_error(PdfCharacterizerService::Error)
      end
    end
  end

  describe '#characterize' do
    let(:characterization) { service.characterize(filepath: 'brief.pdf') }

    context 'when file is characterized' do
      let(:output) do
        <<~OUTPUT
          Creator:        Acrobat PDFMaker 5.0 for Word
          Producer:       Mac OS X 10.9.5 Quartz PDFContext
          CreationDate:   2020-01-18T16:55:26-05
          ModDate:        2020-01-18T16:55:26-05
          Tagged:         no
          UserProperties: no
          Suspects:       no
          Form:           none
          JavaScript:     no
          Pages:          111
          Encrypted:      no
          Page size:      612 x 792 pts (letter)
          Page rot:       0
          File size:      624716 bytes
          Optimized:      yes
          PDF version:    1.6
        OUTPUT
      end

      let(:text_output) do
        <<~OUTPUT
          319
          See generally id., Vol. II. As the Mueller Report summarizes, the Special Counsel’s
          investigation “found multiple acts by the President that were capable of exerting undue influence
          over law enforcement investigations, including the Russian-interference and obstruction
          investigations. The incidents were often carried out through one-on-one meetings in which the
          President sought to use his official power outside of usual channels. These actions ranged from
          efforts to remove the Special Counsel and to reverse the effect of the Attorney General’s recusal; to
          the attempted use of official power to limit the scope of the investigation; to direct and indirect
          contacts with witnesses with the potential to influence their testimony.” Id., Vol. II at 157.
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns pdf attributes' do
        expect(characterization).to eq(creator: 'Acrobat PDFMaker 5.0 for Word',
                                       producer: 'Mac OS X 10.9.5 Quartz PDFContext',
                                       tagged: false,
                                       form: false,
                                       pages: 111,
                                       encrypted: false,
                                       page_size: '612 x 792 pts (letter)',
                                       pdf_version: '1.6',
                                       text: true)
        expect(Open3).to have_received(:capture2e).with('pdfinfo', 'brief.pdf')
        expect(Open3).to have_received(:capture2e).with('pdftotext', 'brief.pdf', '-')
      end
    end

    context 'when file has no text' do
      let(:output) do
        <<~OUTPUT
          Creator:        Acrobat PDFMaker 5.0 for Word
        OUTPUT
      end

      let(:status) { instance_double(Process::Status, success?: true) }

      it 'returns false for text attribute' do
        expect(characterization[:text]).to be_falsey
      end
    end

    context 'when poppler fails' do
      let(:status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises' do
        expect { characterization }.to raise_error(PdfCharacterizerService::Error)
      end
    end
  end
end
