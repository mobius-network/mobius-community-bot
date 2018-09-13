class FetchReserveAccountsAction
  extend LightService::Action
  promises :reserve_accounts

  executed do |context|
    context.reserve_accounts =
        company_reserve_accounts +
        cofounder_lockup_accounts +
        revoked_accounts
  end

  def self.company_reserve_accounts
    [
        'GCHDGFUGRMN5BR74LEBUMHHTWYIBIMI6M2LL2K3EQSRUF6GV6MAT4ZQK', # cold wallet
        'GASQH4XYX2TR4KZE4VMUNELK4L5JPJQJEJZCMZHJ3L4ELPZGF6QGRLMD', # hot wallets
        'GAE5D4VQGUK4RCRFGAOEAODXOURFDWYWOTXV2ZFFNFJ3MPDH36BLSBN2',
        'GCQTYNLMBN43D66AXDW56KZIKE6X3QOKYITNGY5MBL7X5GMOLE6JPL2C',
        'GDYDVSVUV7EJDUPEM3KPQ2E2YHKOLXOUP77T4M4Q3LI4VQCYUL6HJLUT',
        'GDANMFM6HY7SEOB3B7YRNHNND23S3WFWQYRATXJSUY4SM7E5PSHAETHF',
        'GC7TAK53TS5JRG4WL26GTSBWWQPZPJZ6MWE4ZQTLLSDZOOPJPSLUY7AG',
        'GDEUJPHCOKBAHGGM4G7F23GKLPZU4J3LP2UUS2Z4QRP2OZQUD77Y4QR5',
        'GB2CVZFQ5U2VYEW3PUUGQL6DTYAAW7E6MN3OFCVP2CYG6RZP3EMQSZIN', # mobi distribution
    ]
  end

  def self.cofounder_lockup_accounts
    %W[
      GBWYDFPFQYXXMRWFHQVY7426RNNRAPVHFR5G4ACVAZXFUKZO65PJP3H7
      GDKTC44HPCLWAUWIO4ROEKAKKK5IS4PFGKRKWNRO4657SDJTSISNVET4
      GCGQ2DZH5ZNRSX3FFZHVO6XZSAE3PFYILIGJOT7CP4KB3YM3AXG7SDPI
      GAOMPG27UK62HUFTB27BEC6AGKXQTQDWPTMZVGXLMK32EHPBARMJ3SNT
    ]
  end

  def self.revoked_accounts
    %W[
      GBLP4BVBZDTJX3WSKCBNXVQYMP5SL42DQTHVWHJFQL7GLPBKG3NCEHEW
      GDWDEEZW225RODW4K5TXPBUISOYWVJBZ23TSUKWFJNE4QLHRL6AHGMBJ
      GC66JBDLCKYPBIDZBG7K32RHEQ65KHDWLOBGNRYZT5WWFTYBMW4Q2D4F
      GDEHOGC36P3HWSOGR5NB4S2JBK5IBJEO2XY6TVCLLRVB2KSVVTNIJG33
      GB24XDJLWN5SZ6SJHWUDZ3AY5CX4W25AWTAHXZXXVMZ6ZYQFG6CRE7WG
      GA26Q7MLLEEBU7XXYZCF5P7GPK6WVQWDMWURTHO742UYNUOVDRNEWV2N
      GAR7652UYAVZUO3EZ56WAVS3XVIR4AH6ENDT6RYLIUP4KDACPZ245EIE
      GD66KFUKU7HB55MZVBCJ2BSLVFEUFXQY46WUTBQDFLY5NBI6TQOATJMU
      GDZQ6T6KNI5SN6BJBEAEJL4HGXL5623T5Q5JLQAWDD5HIPMAM25EAKIZ
    ]
  end
end
