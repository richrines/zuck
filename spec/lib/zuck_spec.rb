require 'spec_helper'

describe Zuck::FbObject do

  before(:all) do
    Zuck.graph = Koala::Facebook::API.new('AAAEvJ5vzhl8BAG3qjJXGVUVKTzjMLrirxcVxllKJdthkQrEstIgXzMYZAAzg0ETsCGMGmX9UvUh4ZCGvATX9ZCnjNee18OTtQ9ZAarrDBQZDZD')
  end

  let(:graph)   { Zuck.graph                                                  }
  let(:account) { Zuck::AdAccount.new(graph,  {id: "act_10150585630710217"})  }
  let(:campaign){ Zuck::AdCampaign.new(graph, {id: "6004497037951"}, account) }
  let(:group)   { Zuck::AdGroup.new(graph,    {id: "6004497038951"}, campaign)}
  let(:creative){ Zuck::AdCreative.new(graph, {id: "1234567890123"}, group)   }


  describe "read only objects" do
    it "can't be created" do
      expect{
        Zuck::AdCreative.create(:x, {}, :y)
      }.to raise_error(Zuck::Error::ReadOnly)
    end

    it "can't be saved" do
      expect{
        creative.save
      }.to raise_error(Zuck::Error::ReadOnly)
    end

    it "can't be destroyed" do
      expect{
        creative.destroy
      }.to raise_error(Zuck::Error::ReadOnly)
    end
  end

  describe "talking to facebook" do
    context "reading" do

      it "a list of ad accounts" do
        VCR.use_cassette('list_of_ad_accounts') do
          Zuck::AdAccount.all.should have(1).item
        end
      end

      it "a list of ad campaigns" do
        VCR.use_cassette('list_of_ad_campaigns') do
          account.ad_campaigns.should have(1).item
        end
      end

      it "a list of ad groups" do
        VCR.use_cassette('list_of_ad_groups') do
          campaign.ad_groups.should have(3).items
        end
      end

      it "list of ad creatives" do
        VCR.use_cassette('list_of_ad_creatives') do
          group.ad_creatives.should have(1).items
        end
      end

      context "an id directly" do

        let(:graph){ Koala::Facebook::API.new('AAAEvJ5vzhl8BAPJfh51jolSxTzQCyIfLvJ1ZAVZCfjDHssTLpyYaIK3rqTeKvYBrydUeGtvA9DZAquQZAuoVZB6we8H9DUD9R6iE0yKluXAZDZD') }

        it "with the correct type" do
          VCR.use_cassette('a_single_campaign') do
            c = Zuck::AdCampaign.find(6004497037951, graph)
          end
        end

        it "when expecting an ad group but the id belongs to a campaign" do
          VCR.use_cassette('a_single_campaign') do
            expect{
              c = Zuck::AdGroup.find(6004497037951, graph)
            }.to raise_error("Invalid type: neither adgroup_id nor group_id set")
          end
        end

        it "and saving it" do
          VCR.use_cassette('find_a_single_campaign_and_update_it') do
            graph = Koala::Facebook::API.new('AAAEvJ5vzhl8BALRaa2dRQ6BkK7dU2ZB6R7n9xfGif8Xnmqu5KKRHWUSLlmDXXO5lo1e8fJZAMeppR7QQtGvpnPNSBkrI1DwGHxXRrnfQZDZD')
            group = Zuck::AdGroup.find(6005859287551, graph)
            group.name = "My new name"
            group.save
            group.name.should == "My new name"
            group.reload
            group.name.should == "My new name"
          end
        end

      end
    end


    context "creating" do
      let(:graph){ Koala::Facebook::API.new('AAAEvJ5vzhl8BAAExaMreeha9sPAZASaclkkuheSlbjjbiSKwcYcbdC5boZBxyCevcnx5YbY0kyd7YVJNjmrqDt0ZCJAXJbJPCLQdfqeTwZDZD') }

      it "an ad campaign" do
        VCR.use_cassette('create_ad_campaign') do
          o = {daily_budget: 1000, name: "bloody" }
          campaign = Zuck::AdCampaign.create(graph, o, account)
          campaign.name.should == "bloody"
        end
      end

      it "an ad campaign via an existing ad account" do
        VCR.use_cassette('create_ad_campaign') do
          o = {daily_budget: 1000, name: "bloody" }
          campaign = account.create_ad_campaign(o)
          campaign.name.should == "bloody"
        end
      end

      it "an ad group" do
        VCR.use_cassette('create_ad_group') do
          o = {bid_type: 1, max_bid: 1, name: "Rap like me", targeting: '{"countries":["US"]}',
               creative: '{"type":25,"action_spec":{"action.type":"like", "post":10150420410887685}}'}
          group = Zuck::AdGroup.create(graph, o, campaign)
          group.name.should == "Rap like me"
        end
      end

      it "an ad group via an existing ad campaign" do
        VCR.use_cassette('create_ad_group') do
          o = {bid_type: 1, max_bid: 1, name: "Rap like me", targeting: '{"countries":["US"]}',
               creative: '{"type":25,"action_spec":{"action.type":"like", "post":10150420410887685}}'}
          group = campaign.create_ad_group(o)
          group.name.should == "Rap like me"
        end
      end
    end

    context "deleting" do
      let(:graph){ Koala::Facebook::API.new('AAAEvJ5vzhl8BAPJfh51jolSxTzQCyIfLvJ1ZAVZCfjDHssTLpyYaIK3rqTeKvYBrydUeGtvA9DZAquQZAuoVZB6we8H9DUD9R6iE0yKluXAZDZD') }

      it "an ad group" do
        VCR.use_cassette('delete_ad_group') do
          ad_group = Zuck::AdGroup.new(graph, id: '6005859287551' )
          ad_group.destroy.should be_true
        end
      end
    end

  end
end
