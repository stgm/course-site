module User::BadSubmitEmailThrottler
  extend ActiveSupport::Concern

  # Bepaalt of er een e-mail gestuurd moet worden op basis van het aantal 
  # recente submissions binnen het uur
  def should_send_bad_submit_email?
    # Verwijder oude timestamps (ouder dan 1 uur)
    clean_old_email_timestamps
    
    # Haal het aantal e-mails op dat in het afgelopen uur is verstuurd
    recent_email_count = bad_submit_email_timestamps.count
    
    # Logica voor het verminderen van e-mails:
    # - Eerste afgekeurde inlevering: stuur e-mail (100% kans)
    # - Tweede afgekeurde inlevering: stuur e-mail (50% kans) 
    # - Derde afgekeurde inlevering: stuur e-mail (25% kans)
    # - Vierde en meer: stuur e-mail (10% kans)
    
    case recent_email_count
    when 0
      true  # Eerste keer: altijd e-mail sturen
    when 1  
      rand < 0.5  # 50% kans
    when 2
      rand < 0.25 # 25% kans
    else
      rand < 0.1  # 10% kans voor 3+ e-mails
    end
  end

  # Registreer dat er een e-mail is verstuurd
  def record_bad_submit_email_sent
    clean_old_email_timestamps
    self.bad_submit_email_timestamps = (bad_submit_email_timestamps || []) + [Time.current.to_i]
    update_columns(bad_submit_email_timestamps: bad_submit_email_timestamps)
  end

  private

  # Verwijder timestamps die ouder zijn dan 1 uur
  def clean_old_email_timestamps
    return unless bad_submit_email_timestamps.present?
    
    one_hour_ago = Time.current - 1.hour
    self.bad_submit_email_timestamps = bad_submit_email_timestamps.select do |timestamp|
      Time.at(timestamp.to_i) > one_hour_ago
    end
  end
end
